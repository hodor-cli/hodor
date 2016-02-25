
module Hodor
  module Cli
    class Sandbox < ::Hodor::Command
      #
      # Manual change required:
      #
      # edit /etc/hadoop/conf/core-site.xml
      #
      # Change the following sections to agree with:
      #
      # <property
      #    <name>hadoop.proxyuser.oozie.hosts</name>
      #    <value>*</value>
      # </property>
      #
      # <property>
      #      <name>hadoop.proxyuser.oozie.groups</name>
      #      <value>*</value>
      # </property>
      #

      no_tasks do
        def ssh_user_addr(user_key)
          va = "#{env[user_key]}@#{env[:ssh_host]}"
          va << " -p #{env[:ssh_port] || 22}"
        end

        def deploy_ssh_key(user_key)
          logger.info "Preventing future password prompts for '#{env[user_key]}' sandbox user."
          logger.info "Note: this may require you to enter the password for '#{env[user_key]}'."
          remote_cmd = %q['umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys; cat >> ~/.ssh/authorized_keys']
          env.run_local %Q[cat ~/.ssh/id_rsa.pub | ssh #{ssh_user_addr(user_key)} #{remote_cmd}], echo: true, echo_cmd: true
        end

        def self.help(shell, subcommand = false)
          overview = %Q[Hodor's Sandbox namespace functions as a local proxy for Hortonworks "HDP Sandbox" that you may have
          running in a virtual machine. The commands in this namespace are responsible for performing one-time
          initialization tasks on the sandbox virtual cluster, so that expected user accounts are created etc.
          To be clear, Hodor generally does not require that you run Hortonwork's Sandbox. Only this particular
          namespace expects that. So, if you aren't running one, just avoid use of this namespace.

          Note: this namespace has not be used in well over a year and is probably broken right now. It needs
          to be reviewed and updated or overhauled. Meanwhile, use at your own risk.

          ].unindent(10)
          shell.say overview
          result = super

          more_help = %Q[Getting More Help:
          ------------------
          To get detailed help on specific Sandbox commands (i.e. setup_ssh), run:

             $ hodor help sandbox:setup_ssh
             $ hodor sandbox:help setup_ssh    # alternate, works the same

          ].unindent(10)
          shell.say more_help
          result
        end
      end

      # Set up a hortonworks sandbox. Currently, all this does is copy your SSH key
      # to avoid password prompting. In the future, we may want to install components
      # we expect to be available, etc.
      desc "setup_ssh", "Set up a new sandbox to include required components and SSH keys"
      def setup_ssh
        deploy_ssh_key(:ssh_user)
      end

      desc "setup_users", "Set up a new sandbox to include required components and SSH keys"
      def setup_users
        deploy_ssh_key(:oozie_user)
      end

      desc "setup_hdfs", "Set up a new sandbox to include hdfs directories with required group settings"
      def setup_hdfs
        oozie_root = env[:oozie_root] || 'pipeline'
        invoke "hdfs:fs", %w[-u hdfs -mkdir /shared]
        invoke "hdfs:fs", %W[-u hdfs -mkdir /#{oozie_root}]

        invoke "hdfs:fs", %w[-u hdfs -chgrp hadoop /shared]
        invoke "hdfs:fs", %W[-u hdfs -chgrp hadoop /#{oozie_root}]
      end
    end
  end
end
