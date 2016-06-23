
module Hodor
  module Cli

    class Master < ::Hodor::Command

      no_tasks do
        def intercept_dispatch(command, trailing)
          case command
          when :exec
            hadoop_command("-T", trailing)
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

      desc "secrets", "List all known secrets for the environment"
      def secrets
        logger
        env.secrets.each_pair { |k,v|
          logger.info "#{k} :  #{v}"
        }
      end

      desc "print", "print values of named key/value pairs from the clusters.yml file"
      long_desc <<-LONGDESC
       Prints the value of a list of keys for the environment currently target.
       The list of keys can have 0 to any number of items, and each value will
       be printed separately for each key. If print is called without any keys
       the entire set of keys for the current environment will be displayed.

       Example Usage:

       $ hodor master:print
       $ hodor master:print ssh_user
       $ hodor master:print ssh_user target oozie_url
      LONGDESC
      def print(*vars)
        if vars.empty?
          ap env.settings
        else
          vars.each { |var|
            puts env.settings[var.to_sym]
          }
        end
      end

      desc "exec <arguments>", %q{
        Pass through command that executes its arguments on the remote master via ssh
      }.gsub(/^\s+/, "").strip
      long_desc <<-LONGDESC
       Executes the shell command on the remote host configured as the master,
       ussing SSH. The arguments passed to this command are passed directly
       through to the ssh command and executed as-is on the remote host.

       Example Usage:

       $ hodor master:exec hostname -I
      LONGDESC
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
