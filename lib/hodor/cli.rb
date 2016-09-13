require "thor/runner"

module Hodor::Cli
  class Usage < StandardError
  end

  class CommandNotFound < StandardError
  end

  class AbnormalExitStatus  < StandardError
    attr_reader :exit_status
    def initialize(exit_status, error_lines)
      @exit_status = exit_status
      super error_lines
    end
  end

  class Runner < ::Thor::Runner

    attr_reader :topic_paths

    def help(meth = nil)
      if meth && !self.respond_to?(meth)
        super
      else
        overview = %Q[Hodor is an object-oriented scripting toolkit and Ruby-based API that automates and simplifies the way you
          specify, deploy, test, inspect and administer your hadoop cluster and Oozie workflows. Hodor commands follow
          the convention of:

             $ hodor [namespace]:[command] [arguments] [options]

          To get more information about the namespaces and commands available in Hodor, run:

             $ hodor -T

          WARNING! Hodor must be run via 'bundle exec'. For example:

             $ bundle exec hodor -T

          Note: examples shown in help pages don't show the 'bundle exec' prefix because they assume you have the following alias in place:

             $ alias hodor='bundle exec hodor'
        ].unindent(10)
        say overview
      end
    end

    desc "list [SEARCH]", "List the available thor commands (--substring means .*SEARCH)"
    method_options :substring => :boolean, :group => :string, :all => :boolean, :debug => :boolean
    def list(search = "")
      overview = %Q[
        Hodor's Namespaces & Commands
        ======================================================================================================
        Hodor divides its command set into the namespaces shown below (e.g. 'oozie', 'hdfs', 'master' etc.) Each
        namespace contains a set of commands that support the overall purpose of its parent namespace. For example, the
        hdfs namespace includes commands to list, put and get files to/from a remote HDFS volume. The following table shows
        all the namespaces Hodor supports, along with a short description of the commands that fall within each namespace.

      ].unindent(8)

      say overview
      super

      more_help = %Q[Getting More Help:
        ------------------
        Each Hodor namespace offers full help, including an overview of the namespace itself, references to "topic
        pages" that explain core concepts implemented by the namespace and detailed help for each command that falls
        within the namespace. To access help for a Hodor namespace, run hodor passing <namespace> as the sole
        argument. For example, to see help for Hodor's Oozie namespace, run:

          $ hodor oozie
          $ hodor help oozie   # alternate, works the same

        Furthermore, to see detailed help for the oozie:display_job command, run:

          $ hodor help oozie:display_job
          $ hodor oozie:help display_job    # alternate, works the same

        Lastly, to see the topic page that explains the "corresponding paths" concept, that is central to the
        Hdfs namespace, run:

          $ hodor hdfs:topic corresponding_paths

        And to obtain a list of all topics available within the oozie namespace, for example, run:

          $ hodor oozie:topics
      ].unindent(8)
      say more_help
    end


    def method_missing(meth, *args)
      if args[0].eql?('nocorrect')
        fail %Q[You are using a shell alias with an improper trailing space. For example:
                     alias dj='bundle exec hodor oozie:display_job' (works)
                     alias dj='bundle exec hodor oozie:display_job ' (fails)]
      end
      super meth, *args
    rescue
      raise
    end

    def self.handle_no_command_error(command, bv)
      raise CommandNotFound.new("No Such Command: #{command.inspect}")
    end

    no_tasks do
      def thorfiles(*args)
        plugins = []
        Gem.find_latest_files('**/*.thor').each { |path|
          plugins << path if path =~ /\/hodor-.*/
        }

        @topic_paths = plugins

=begin
        plugins.each_with_index { |plugin, index|
          puts "PLUGIN #{index} : #{plugin}"
        }
=end

        plugins + Dir[File.join(File.dirname(__FILE__), '..', 'tasks/**/*.thor')].map { |path| File.expand_path(path) }
      end

    end

  end
end

module Hodor
  module Cli
  end
end


class Thor
  module Shell
    class Basic # rubocop:disable ClassLength
      def print_wrapped(message, options = {})
        indent = options[:indent] || 0
        width = terminal_width - indent - 5
        paras = message.split("\n\n")

        paras.map! do |unwrapped|
          unwrapped.strip.gsub(/\n([^\s\-\005])/, ' \1').gsub(/.{1,#{width}}(?:\s|\Z)/) {
            ($& + 5.chr).gsub(/\n\005/, "\n").gsub(/\005/, "\n")
          }
        end

        paras.each do |para|
          para.split("\n").each do |line|
            stdout.puts line.insert(0, " " * indent)
          end
          stdout.puts unless para == paras.last
        end
      end
    end
  end
end

require_relative "command"
require_relative "ui/table"
