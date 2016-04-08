require 'thor'

module Hodor
  class Command < ::Thor

    no_tasks do

      def env
        Environment.instance
      end

      def target
        env.settings[:target]
      end

      def logger
        env.logger
      end

      # Part of workaround to prevent parent command arguments from being appended
      # to child commands
      #  NOTE: the args argument below should actually be *args.
      def invoke(name=nil, *args)

        name.sub!(/^Hodor:/, '') if name && $hodor_runner
        super(name, args + ["-EOLSTOP"])
      end

      def invoke_command(command, trailing)
        env.options = options
        @invoking_command = command.name
        workaround_thor_trailing_bug(trailing)
        erb_expand_command_line(trailing)
        @trailing = trailing

        if self.respond_to?(:intercept_dispatch)
          @was_intercepted = false
          intercept_dispatch(command.name.to_sym, trailing)
          super unless @was_intercepted
        else
          super
        end
      rescue Hodor::Cli::Usage => ex
        logger.error "CLI Usage: #{ex.message}"
      rescue SystemExit, Interrupt
      rescue => ex
        if env.prefs[:debug_mode]
          logger.error "EXCEPTION! #{ex.class.name} :: #{ex.message}\nBACKTRACE:\n\t#{ex.backtrace.join("\n\t")}"
        else
          logger.error "#{ex.message}\nException Class: '#{ex.class.name}'"
        end
      end

      # This function works around a bug in thor. Basically, when one thor command
      # calls another (ie. via "invoke"), the parent command's last argument is
      # appended to the arguments array of the invoked command.  This function
      # just chops off the extra arguments that shouldn't be in the trailing string.
      def workaround_thor_trailing_bug(trailing)
        sentinel = false
        trailing.select! { |element| 
          sentinel = true if element.eql?("-EOLSTOP")
          !sentinel
        }
      end

      # Expand any ERB variables on the command line against the loaded environment. If
      # the environment has no value for the specified key, leave the command line unchanged.
      # 
      # Examples:
      #   $ bthor sandbox:oozie --oozie "<%= env[:oozie_url] %>"
      #   $ bthor sandbox:oozie --oozie :oozie_url
      #
      # Note: Either of above works, since :oozie_url is gsub'd to <%= env[:oozie_url] %>
      #
      def erb_expand_command_line(trailing)
        trailing.map! { |subarg| 
          env.erb_sub(
            subarg.gsub(/(?<!\[):[a-zA-Z][_0-9a-zA-Z~]+/) { |match|
              if env.settings.has_key?(match[1..-1].to_sym)
                "<%= env[#{match}] %>" 
              else
                match
              end
            }
          )
        }
      end

      def hadoop_command(cmd, trailing)
        @was_intercepted = true
        cmdline = cmd ? "#{cmd} " : ""
        cmdline << trailing.join(' ')
        env.ssh cmdline, echo: true, echo_cmd: true
      end

      def dest_path
        options[:to] || "."
      end

      def scp_file(file)
        # If the file has .erb extension, perform ERB expansion of the file first
        if file.end_with?('.erb')
          dest_file = file.sub(/\.erb$/,'')
          erb_expanded = env.erb_load(file)
          src_file = "/tmp/#{File.basename(dest_file)}"
          File.open(src_file, 'w') { |f| f.write(erb_expanded) }
        else
          dest_file = "#{options[:parent] || ''}#{file}"
          src_file = file
        end

        file_path = "#{dest_path}/#{File.basename(src_file)}"
        env.run_local %Q[scp #{src_file} #{env.ssh_user}@#{env[:ssh_host]}:#{file_path}],
        echo: true, echo_cmd: true
        return file_path
      end

      def self.load_topic(title)
        topics = File.join(File.dirname(__FILE__), '..', '..', 'topics', name.split('::').last.downcase)
        contents = File.open( File.join(topics, "#{title}.txt"), 'rt') { |f| f.read }
        contents.gsub(/^\\x5/, "\x5")
      end

      def load_topics
        topics = File.join(File.dirname(__FILE__), '..', '..', 'topics', self.class.name.split('::').last)
        Dir.glob(File.join(topics, '*.txt'))
      end
    end

    desc "topic [title]", "Display named help topic [title]"
    def topic(title)
      say self.class.load_topic(title)
    end

    desc "topics", "Display a list of topic discussions available for the namespace"
    def topics
      say "The following topics (in no particular order) are available within the namespace:"
      load_topics.each_with_index { |topic, i|
        say "  Topic: #{File.basename(topic).sub(/.txt$/, '')}"
      }
    end

    class << self
      def inherited(base) #:nodoc:
        base.send :extend,  ClassMethods
      end
    end

    module ClassMethods
      def namespace(name=nil)
        case name
        when nil
          constant = self.to_s.gsub(/^Thor::Sandbox::/, "")
          strip = $hodor_runner ? /^Hodor::Cli::/ : /(?<=Hodor::)Cli::/
          constant = constant.gsub(strip, "")
          constant =  ::Thor::Util.snake_case(constant).squeeze(":")          
          @namespace ||= constant
        else
          super
        end
      end
    end
  end
end
