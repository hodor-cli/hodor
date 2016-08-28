require 'singleton'

require 'log4r'
require 'log4r/configurator'
require 'tmpdir'
require 'open4'
require 'socket'
require 'etc'
require_relative 'util/yml_tools'
require_relative 'config_set'

include Log4r

module Hodor
  class Environment
    include Singleton
    include Util::YmlTools
    attr_reader :logger
    attr_accessor :options

    def root
      begin
        @root = run_local "git rev-parse --show-toplevel", raise_on_error: true
      rescue Hodor::Cli::AbnormalExitStatus => ex
        puts "#{ex.message.strip}\nHodor must be run inside a Git working tree. Aborting..."
        Kernel.exit
      end if @root.nil?
      @root
    end

    def logger_id
      'MainLogger'
    end

    def logger
      begin
        if File.exists?(File.join(root, 'config', 'log4r_config.xml'))
          ::Configurator.load_xml_file(File.join(root, 'config', 'log4r_config.xml'))
        else
          ::Configurator.load_xml_string(%q[
              <log4r_config>

                <!-- Logging Levels -->
                <pre_config>
                  <custom_levels>DEBUG, INFO, SSHCMD, STDOUT, STDERR, WARN, ERROR, FATAL</custom_levels>
                  <global level="DEBUG"/>
                </pre_config>

                <!-- Outputters -->
                <outputter name="logconsole" type="StdoutOutputter" level="DEBUG" >
                </outputter>

                <outputter name="console" type="StdoutOutputter" level="DEBUG" >
                  <formatter type="Log4r::PatternFormatter">
                    <pattern>%5l|%M</pattern>
                  </formatter>
                </outputter>

                <!-- Loggers -->
                <logger name="MainLogger"
                  level="INFO" additive="false" trace="true">
                  <outputter>console</outputter>
                </logger>

                <!-- Rspec Loggers -->
                <logger name="RspecLogger"
                  level="WARN" additive="false" trace="true">
                  <outputter>console</outputter>
                </logger>

              </log4r_config>
          ])
        end
        @logger = Log4r::Logger[logger_id]
      rescue => ex
        puts "Error:  #{ex.message}"
      end if @logger.nil?
      @logger
    end

    # Events plugins can listen to

    def register_listener(plugin)
      @plugins << plugin
    end

    def command_pending(command, trailing)
      @plugins.each { |plugin|
        plugin.command_pending(command, trailing) if plugin.respond_to?(:command_pending)
      }
    end

    def command_succeeded(command, trailing)
      @plugins.each { |plugin|
        plugin.command_succeeded(command, trailing) if plugin.respond_to?(:command_succeeded)
      }
    end

    def command_failed(command, trailing, exception)
      @plugins.each { |plugin|
        plugin.command_failed(command, trailing, exception) if plugin.respond_to?(:command_failed)
      }
    end

    def terse?
      options[:terse]
    end

    def silent?
      options[:silent]
    end

    def verbose?
      options[:verbose]
    end

    def dryrun?
      options[:dryrun]
    end

    def clean?
      options[:clean]
    end

    def hadoop_env
      @bind_to || ENV['HADOOP_ENV'] || 'sandbox'
    end

    def initialize
      @options = {}
      @plugins = []
      # Logger fails if attempt is made to use it before it is loaded
      # so it is preloaded here.
      logger
    end

    def secrets
      @secrets ||= Hodor::ConfigSet.new(:secrets).config_hash
    end

    def clear_secrets
      @secrets = nil
    end

    def load_settings
      unless @loaded
        target_env = hadoop_env.to_sym
        @clusters = yml_load('config/clusters.yml')
        secrets
        @clusters.recursive_merge!(@secrets) if @secrets
        Hodor::ConfigSet.check_for_missing_configs(@clusters, :fail)
        @target_cluster = @clusters[target_env]
        if @target_cluster.nil?
          raise "The target environment '#{target_env}' was not defined in the config/clusters.yml file. Aborting..."
        end

        if File.exist?('config/local.yml')
          @target_cluster.merge! yml_load('config/local.yml')
        end

        @target_cluster[:target] = target_env
        @loaded = true
      end
      yml_expand(@target_cluster, [@clusters])
    end

    def prefs
      if @prefs.nil?
        preffile = "#{Etc.getpwuid.dir}/.hodor.yml"
        @prefs = yml_load(preffile) if File.exists?(preffile)
        @prefs ||= {}
        @prefs = @prefs.normalize_keys
      end
      @prefs
    end

    def reset(target_env = nil)
      @bind_to = target_env.nil? ? nil : target_env.to_s
      @clusters = nil
      @target_cluster = nil
      @loaded = false
      @jobs = nil
      @run = nil
    end

    def path_on_github(path = nil)
      if path
        if path.start_with?('/')
          abspath = true
          lpath = path
        else
          relpath = true
        end
      end
      lpath ||= FileUtils.pwd

      lpath = lpath.sub(root, '')
      git_path = relpath ? "#{lpath}/#{path}" : lpath
      git_path = git_path.sub(/\/\//, '/').sub(/\/\.\//, '/').sub(/\/\.$/, '').sub(/\/$/, '')

      if git_path.end_with?('..')
        up_index = git_path.rindex(/[^\.]\//)
        if up_index > 0
          last_path = git_path[0..up_index]
          up_path = git_path[up_index+2..-1]
          up_paths = up_path.split('/')
          abs_path = File.expand_path(File.join(up_paths), "#{root}/#{last_path}".sub(/\/\//, '/'))
          git_path = path_on_github(abs_path)
        end
      end

      git_path
    end

    def path_on_disc(path = nil)
      relpath = path_on_github(path)
      "#{root}/#{relpath}".sub(/\/\//, '/').sub(/\/$/, '')
    end

    def pwd(path = nil)
      if path
        if path.start_with?('/')
          abspath = true
          lpwd = path
        else
          relpath = true
        end
      end
      lpwd ||= FileUtils.pwd
      rpwd = lpwd.sub(root, '')
      if rpwd.length < lpwd.length
        lpwd = rpwd[1..-1] if rpwd.start_with?('/')
      else
        lpwd = rpwd
      end
      relpath ? "#{lpwd}/#{path}" : lpwd
    end

    def abs_path(path)
      "#{root}/#{path}"
    end

    def paths_from_root(end_path)
      # returns an array of paths from the root of the repo
      paths = []
      curpath = end_path
      loop do
        paths << curpath
        break if curpath == root || curpath.length < root.length || curpath.length == 0
        curpath = File.dirname(curpath)
      end
      paths.reverse
    end

    def target_cluster
      load_settings
      raise "No settings for target cluster '#{hadoop_env}' were loaded" if !@loaded || !@target_cluster
      @target_cluster
    end

    def [](key)
      target_cluster[key]
    end

    def env
      target_cluster
    end

    def select_job(job)
      @job = job
    end

    def job
      @job || {}
    end

    def has_key? key
      target_cluster.has_key? key
    end

    def settings
      target_cluster
    end

    def ssh_user
      env[:ssh_user]
    end

    def hostname
      Socket.gethostname
    end

    def username
      Etc.getpwuid(Process.uid).name
    end

    # Compute SSH command (user, machine and port part)
    def ssh_addr
      va = "#{ssh_user}@#{settings[:ssh_host]}"
      va << " -p #{settings[:ssh_port] || 22}"
    end



    # Run an ssh command, performing any optional variable expansion
    # on the command line that might be necessary.
    #
    # The following variable expansions are supported:
    # env.ssh %Q[ssh ${ssh_addr} ...]  # calls "ssh_addr" function
    # env.ssh %Q[ssh ${env[:ssh_user]} ...] # retrieves value from hash
    # env.ssh %Q[ssh :ssh_user ...] # retrieves value from hash
    # env.ssh %Q[ssh #{env.ssh_addr} ...]  # skip variable expansion.
    #                              Use normal string interpolation instead
    def kvp_expand(script)
      script.gsub!(/:[^\s]+|\$\{.+?\}/) { |match|
        begin
          if match.start_with?(':')
            k = match[1..-1].to_sym
            if settings.has_key?(k)
              val = settings[k]
            else
              val = match
            end
          else
            cv = match.split(/\{|\}/)
            cv = cv[1].split(/\[|\]/)
            fn = cv[0].to_sym
            if self.respond_to?(fn)
              rtn = self.send(fn)
              if cv.size == 1
                val = rtn
              else
                k = cv[1]
                k = k[1..-1].to_sym if k.start_with?(':')
                val = rtn[k]
              end
              val
            else
              match
            end
          end
        rescue StandardError
          match
        end
      }
      script
    end

    # user_args
    #   strip off the "-u <username>" argument, which hadoop commands don't understand.
    #   The username has to be set using an environment variable instead.  This is a
    #   convience method to facilitate this swapping around that is necessary in several
    #   hadoop commands (fs, oozie etc.).
    def extract_sudoer(trailing)
      username_next = false
      username = nil # nil assignment avoids "unused variable" warning
      args = []
      trailing.each { |arg|
        if arg.eql?("-u")
          username_next = arg.eql?("-u")
        elsif username_next
          username = arg
          username_next = false
        else
          args << arg
        end
      }

      return [username, args]
    end

    def ssh script, opts = {}
      opts[:ssh] = true
      run_local script, opts
    end

    def deploy_tmp_file local_file, opts = {}
      deploy_path = "/tmp/#{File.basename(local_file, ".*")}-#{username}-#{hostname}#{File.extname(local_file)}"
      run_local %Q[scp #{local_file} #{settings[:ssh_user]}@#{settings[:ssh_host]}:#{deploy_path}],
                  echo: true, echo_cmd: true
      deploy_path
    end


    # Alternative to system() that (optionally) echos STDOUT as it is
    # appended, rather than after the command completes.
    #
    # command_line - the shell command and arguments to execute
    #   --terse     => if --terse appears on the command line, only
    #                  the native output of the command is printed.
    #                  I.e. the extra output of log4r is suppressed.
    # opts - options to the function, that include:
    #   [:terse]    => only show normal output of command. No log4r extras.
    #   [:echo]     => true  - append stdout and stderr as it is generated
    #               => false - execute the command silently
    #   [:echo_cmd] => true  - log the command to be executed
    #               => false - remain silent
    #   [:raise_on_error]  => true - failed commands raise an exception
    #                      => false - remain silent
    #   [:suppress_expansion]
    #       => true - don't expand key-value pairs in the command line
    #       => false - expand key-value pairs
    #   [:sudo]
    #       => true - invoke with sudo, extracting username from -u argument
    #       => false - run without sudo
    #   [:ssh]
    #       => true - prefix the command with ssh to run remotely
    #       => false - don't prefix command line with ssh
    #
    # Returns stdout/stderr as a string
    def run_local command_line, opts = {}
      if opts[:sudo]
        username, args = extract_sudoer(command_line)
        command_line = "sudo -u #{username} #{args}" if username
      end

      if opts[:ssh]
        ssh_prefix = "ssh #{settings[:ssh_user]}@#{settings[:ssh_host]} "
        ssh_prefix << "-p #{settings[:ssh_port]} -T " unless settings[:ssh_port].nil?
        command_line = ssh_prefix + command_line
      end

      command_line = kvp_expand(command_line) unless opts[:suppress_expansion]
      native_output_only = command_line.include?('--terse') || opts[:terse]
      if native_output_only
        command_line.sub!(' --terse', '')
        opts[:echo] = true
        opts[:echo_cmd] = false
      end
      echo_command_output = opts[:echo] || false
      command_line = "#{command_line}"
      logger.sshcmd "$ #{command_line}" if opts[:echo_cmd]
      command_output = ""
      status = Open4::popen4(command_line) do |pid, stdin, stdout, stderr|
        command_output = capture_output(stdout, stderr, echo_command_output, native_output_only)
      end
      if status.exitstatus != 0
        raise Hodor::Cli::AbnormalExitStatus.new(status.exitstatus, command_output) if opts[:raise_on_error]
      end
      command_output.strip
    rescue Hodor::Cli::AbnormalExitStatus
      raise
    rescue Errno::ENOENT
      raise Hodor::Cli::CommandNotFound, "Bash Error.  Command or file arguments not found." if opts[:raise_on_error]
    end

    private

    def capture_output stdout, stderr, echo_command_output, native_output_only
      stdout_lines = ""
      stderr_lines = ""
      command_output = ""
      loop do
        begin
          # check whether stdout, stderr or both are
          #  ready to be read from without blocking
          IO.select([stdout,stderr]).flatten.compact.each { |io|
            # stdout, if ready, goes to stdout_lines
            stdout_lines += io.readpartial(1024) if io.fileno == stdout.fileno
            # stderr, if ready, goes to stdout_lines
            stderr_lines += io.readpartial(1024) if io.fileno == stderr.fileno
          }
          break if stdout.closed? && stderr.closed?
        rescue EOFError
          # Note, readpartial triggers the EOFError too soon.  Continue to flush the
          # pending io (via readpartial) until we have received all characters
          # out from the IO socket.
          break if stdout_lines.length == 0  &&  stderr_lines.length == 0
        ensure
          # if we acumulated any complete lines (\n-terminated)
          #  in either stdout/err_lines, output them now
          stdout_lines.sub!(/.*\n/) {
            command_output << $&
            if echo_command_output
              if native_output_only
                puts $&.strip
              else
                logger.stdout $&.strip
              end
          end
          ''
          }
          stderr_lines.sub!(/.*\n/) {
            command_output << $&
            if echo_command_output
              if native_output_only
                puts $&.strip
              else
                logger.stderr $&.strip
              end
          end
          ''
          }
        end
      end
      command_output
    end
  end
end
