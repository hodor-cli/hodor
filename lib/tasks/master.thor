
module Hodor
  module Cli

    class Master < ::Hodor::Command

      no_tasks do
        def intercept_dispatch(command, trailing)
          case command
          when :exec
            @was_intercepted = true
            if trailing.length > 0 and trailing[0].start_with?(':')
              raise "Hadoop environment '#{env.hadoop_env}' has no 'commands:' section in clusters.yml" unless env.settings.has_key?(:commands)
              cmdname = trailing[0][1..-1].to_sym
              raise "Command '#{cmdname.to_s}' not found clusters.yml file's 'commands:' section" unless env.settings[:commands].has_key?(cmdname)
              cmd_opts = env.settings[:commands][cmdname]
              cmdline = cmd_opts[:line]
              cmd_opts.delete(:line)
              if trailing.length > 1
                cmdline += ' ' + trailing[1..-1].join(' ')
              end
              env.run_local cmdline, cmd_opts #echo: true, echo_cmd: true
            else
              hadoop_command("-T", trailing)
            end
          end
        end

        def self.help(shell, subcommand = false)
          shell.print_wrapped(load_topic('overview'), indent: 0)
          result = super

          more_help = %Q[Getting More Help:
          ------------------
          To get detailed help on specific Master commands (i.e. config), run:

             $ hodor help master:config
             $ hodor master:help config    # alternate, works the same

          ].unindent(10)
          shell.say more_help
          result
        end
      end

      desc "config", "List all known variable expansions for the target Hadoop environment"
      def config
        env.settings.each_pair { |k,v|
          logger.info "#{k} :  #{v}"
        }
      end

      desc "print", "print value of named key/value pair from the clusters.yml file"
      def print(varname)
        puts env.settings[varname.to_sym]
      end

      desc "exec <arguments>", %q{
        Pass through command that executes its arguments using the shell
      }.gsub(/^\s+/, "").strip
      long_desc %Q[
       Exec runs shell commands, passing its arguments on to the shell. Exec can
       receive two types of commands: direct or pre-configured. Direct commands
       are commands that are specified directly as arguments to exec, and run
       as-is on the remote host. Pre-configured commands are commands that are
       configured in the "commands:" section of the clusters.yml file. Pre-
       configured commands are indicated by a colon (:) prefix. When a command
       starts with a colon, the command by that name is looked up in the clusters.yml
       file, and appended by the exec command with any arguments passed in.

       Example Usage:

       $ hodor master:exec hostname -I
         - Direct command that runs as-is on the remote master node

       $ hodor master:exec :source_hive query.hql
         - Pre-configured command that builds a command line from the "commands"
       section of the clusters.yml file.

       For example, if your clusters.yml file contains:

       :test_cluster:
           :commands:
               :source_hive:
                   :line: beeline -n hadoop -u jdbc:hive2://hadoop-cluster:10000/default -f
                   :ssh: false
                   :echo: true
                   :echo_cmd: true

       Then the second example above will expand and run locally the following command:

       $ beeline -n -u hadoop -u jdbc:hive2://hadoop-cluster:10000/default -f query.hql

       Because cluster specific urls, user names etc. are in the clusters.yml file, exec's
       pre-configured commands feature allows you to write a single shell script or Rakefile
       that can operate on multiple hadoop clusters.

       Note that each command can specify options, including :ssh, :echo, etc.  Commands
       can be run locally or remotely, depending on your setting for :ssh. The settings
       :echo, and :echo_cmd control how verbose the command will be.

      ].unindent(8)
      def exec
        # handled by intercept_dispatch
      end

      desc "ssh_config", "Echo the SSH connection string for the selected hadoop cluster"
      def ssh_config
        puts env.ssh_addr
      end

      default_task :print
    end
  end
end
