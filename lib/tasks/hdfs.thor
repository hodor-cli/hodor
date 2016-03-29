require "hodor/api/hdfs"

module Hodor
  module Cli
    class Hdfs < ::Hodor::Command

      no_tasks do

        def hdfs
          ::Hodor::Hdfs.instance
        end

        def intercept_dispatch(command, trailing)
          hadoop_command("hadoop fs", trailing) if command == :fs
        end

        def self.help(shell, subcommand = false)
          shell.print_wrapped(load_topic('overview'), indent: 0)
          result = super

          more_help = %Q[Getting More Help:
          ------------------
          To get detailed help on specific Hdfs commands (i.e. put_dir), run:

             $ hodor help hdfs:put_dir
             $ hodor hdfs:help put_dir    # alternate, works the same

          ].unindent(10)
          shell.say more_help
          result
        end
      end

      desc "fs <arguments>", %q{
        Passes its arguments is-as to remote host, and runs 'hadoop fs <arguments>'
      }.gsub(/^\s+/, "").strip
      long_desc <<-LONGDESC
       Executes the hadoop fs command on the remote host configured as the master,
       using SSH. The arguments passed to this command are passed directly
       through to the ssh command and executed as-is on the remote host. Because
       this a pass-through command, anything the remote tool can do, is available
       through this facility. So, refer to Apache's documentation on its 'hadoop fs'
       command line tool for details on the sub-commands and arguments it supports.

       Example:

       $ hodor hdfs:fs -ls -R /shared/jars
      LONGDESC
      def fs
        # handled by intercept_dispatch
      end

      desc "users", %q{
      Run an 'hdfs ls' command on the /user directory to list users on HDFS
      }.gsub(/^\s+/, "").strip
      def users
        env.ssh "hadoop fs -ls /user",
          echo: true, echo_cmd: true
      end

      desc "rm <filename>", "Removes <filename> from corresponding path on HDFS"
      def rm(filename)
        logger.info "Removing #{filename}"
        hdfs.rm(filename)
      end

      desc "rm_rf <directory>", "Recursively removes <directory> from corresponding path on HDFS"
      def rm_rf(path)
        logger.info "Removing directory #{path} recursively..."
        hdfs.rm_rf(path)
      end

      desc "ls [<paths> ...]", "Shows a directory listing of the corresponding path on HDFS"
      def ls(*paths)
        paths << "." if paths.length == 0
        hdfs_paths = paths.inject([]) { |memo, path|
          memo << hdfs.path_on_hdfs(path)
        }
        env.ssh "hadoop fs -ls #{hdfs_paths.join(' ')}",
          echo: true, echo_cmd: true
      end

      desc "cat", "Dump contents of file at the corresponding path on HDFS to STDOUT"
      def cat(filename)
        env.ssh "hadoop fs -cat #{hdfs.path_on_hdfs(filename)}",
          echo: true, echo_cmd: true
      end

      desc "put_dir <path>", "Uploads (recursively) the directory at <path> to corresponding path on HDFS"
      method_option :dryrun, type: :boolean, aliases: "-d", default: false,
        desc: "Don't actually deploy the files, just show what would be deployed"
      method_option :clean, type: :boolean, aliases: "-c", default: false,
        desc: "Clean the hdfs target before deploying this directory"
      method_option :verbose, type: :boolean, aliases: "-v", default: false,
        desc: "Log verbose details about which files are deployed and to where"
      method_option :maxdepth, type: :string, aliases: "-m", default: nil,
        desc: "The maximum number of directories deep to copy to HDFS"
      def put_dir(dirpath)
        hdfs.put_dir dirpath, options
      end

      desc "put <filename>", "Uploads <filename> to the corresponding path on HDFS"
      def put(filename)
        hdfs.put_file(filename)
      end

      desc "get <filename>", "Downloads <filename> from the corresponding path on HDFS"
      method_option :diff, type: :boolean, aliases: "-d", default: false,
        desc: "After downloading <filename>, a diff is run between local and remote versions"
      def get(filename)
        hdfs.get_file(filename)
        if options[:diff]
          env.run_local %Q[diff #{filename} #{filename}.hdfs_copy], echo: true, echo_cmd: true
        end
      end

      desc "touchz", "Creates a file of zero length at the corresponding path on HDFS"
      def touchz(filename)
        env.ssh "hadoop fs -touchz #{hdfs.path_on_hdfs(filename)}",
          echo: true, echo_cmd: true
      end

      desc "pwd", "Displays both your local and HDFS working directories, and how they correspond"
      def pwd
        logger.info "Path on localhost : [#{env.path_on_disc('.')}]"
        logger.info "Path on Git repo  : [#{env.path_on_github('.')}]"
        logger.info "Path on HDFS      : [#{hdfs.path_on_hdfs('.')}]"
      end

      desc "path_of", "Displays the path of the specified file or directory"
      def path_of(path)
        logger.info "Path on local disc: [#{env.path_on_disc(path)}]"
        logger.info "Path on GitHub: [#{env.path_on_github(path)}]"
        logger.info "Path on HDFS: [#{hdfs.path_on_hdfs(path)}]"
      end
    end
  end
end
