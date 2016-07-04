require 'hodor'
require 'singleton'

# curl -i "http://sample_domain.com:50070/webhdfs/v1/pipeline?op=LISTSTATUS"
module Hodor

  # HDFS Api wrapper
  class Hdfs
    include Singleton

    def env
      Hodor::Environment.instance
    end

    def logger
      env.logger
    end

    def hdfs_root
      env.settings[:hdfs_root]
    end

    def pwd
      "#{hdfs_root}#{env.pwd}"
    end

    def path_on_hdfs(file)
      git_path = env.path_on_github(file)
      "#{hdfs_root}/#{git_path}".sub(/\/\/\//, '/').sub(/\/\//, '/').sub(/\/\.\//, '/').sub(/\/\.$/, '')
    end

    def user
      env.settings[:hdfs_user]
    end

    def target
      env.settings[:target]
    end

    class FailedToRemovePath < Hodor::NestedError; end

    def rm(path)
      dest_path = path_on_hdfs(path||".")
      rm_path_script = %Q[HADOOP_USER_NAME=#{user} hadoop fs -rm -skipTrash #{dest_path}]
      env.ssh rm_path_script
    rescue StandardError => ex
      raise FailedToRemovePath.new ex,
        msg: "Unable to remove HDFS path.",
        ssh_user: env.ssh_user,
        path_to_remove: dest_path
    end

    def rm_f(path)
      dest_path = path_on_hdfs(path||".")
      rm_path_script = %Q[HADOOP_USER_NAME=#{user} hadoop fs -rm -f -skipTrash #{dest_path}]
      env.ssh rm_path_script
    rescue StandardError => ex
      raise FailedToRemovePath.new ex,
        msg: "Unable to remove HDFS path.",
        ssh_user: env.ssh_user,
        path_to_remove: dest_path
    end

    def rm_rf(path)
      hdfs_path = path_on_hdfs(path||".")
      rm_path_script = %Q[HADOOP_USER_NAME=#{user} hadoop fs -rm -f -R -skipTrash #{hdfs_path}]
      env.ssh rm_path_script
    rescue StandardError => ex
      raise FailedToRemovePath.new ex,
        msg: "Unable to remove HDFS path.",
        ssh_user: env.ssh_user,
        path_to_remove: dest_path
    end

    def ls
      dest_path = path_on_hdfs(".")
      ls_script = %Q[HADOOP_USER_NAME=#{user} hadoop fs -ls #{dest_path}]
      env.ssh ls_script, echo:true
    rescue StandardError => ex
      raise FailedToRemovePath.new ex,
        msg: "Unable to list HDFS path.",
        ssh_user: env.ssh_user,
        path_to_list: dest_path
    end

    class FailedToPutFile < Hodor::NestedError; end

    # put_file
    #  Puts a local file on HDFS, preserving path and replacing if necessary. Files
    #  with .erb extensions are ERB expanded before deployment.
    def put_file(file, options = {})

      disc_path = env.path_on_disc(file)
      hdfs_path = path_on_hdfs(file)
      git_path = env.path_on_github(file)

      raise "File '#{disc_path}' not found." if !File.exists?(disc_path)

      logger.info "\tdeploying '#{git_path}'"

      src_file = file
      if disc_path.end_with?('.erb')
        erb_expanded = env.erb_load(disc_path)
        src_file = "/tmp/#{File.basename(disc_path.sub(/\.erb$/,''))}"
        hdfs_path.sub!(/\.erb$/, '')
        puts "ends with erb srcfile = #{src_file}"
        File.open(src_file, 'w') { |f| f.write(erb_expanded) }
      end

      raise "File '#{src_file}' not found." if !File.exists?(src_file)

      put_script = "HADOOP_USER_NAME=#{user} hadoop fs -put - #{hdfs_path}"
      unless options[:already_cleaned]
        rm_script = "HADOOP_USER_NAME=#{user} hadoop fs -rm -f #{hdfs_path}; "
        put_script = rm_script + put_script
      end

      env.run_local %Q[cat #{src_file} | ssh #{env.ssh_addr} "#{put_script}"],
        echo: true, echo_cmd: true
    rescue StandardError => ex
      raise FailedToPutFile.new ex,
        msg: "Unable to write file to HDFS.",
        ssh_user: env.ssh_user,
        path_on_disc: disc_path,
        path_on_github: git_path,
        path_on_hdfs: hdfs_path,
        src_file: src_file
    end

    class FailedToPutDir < Hodor::NestedError; end

    def put_dir(path, options)
      if env.dryrun? and env.verbose?
        logger.info ""
        logger.info "        ********************* Dry Run *********************"
        logger.info ""
      end

      pushd = options[:pushd]
      if pushd
        original_pwd = FileUtils.pwd
        FileUtils.cd(options[:pushd])
      end

      disc_path = env.path_on_disc(path)
      git_path = env.path_on_github(path)
      hdfs_path = path_on_hdfs(path)

      sync_file = "#{disc_path}/.hdfs-#{target}.sync"

      logger.info "Deploying: #{git_path}" unless env.silent?

      fail "Path '#{disc_path}' not found." unless File.exists?(disc_path)
      fail "Path '#{disc_path}' exists but is not a directory." unless File.directory?(disc_path)

      if env.clean?
        logger.info "  cleaning: #{git_path}"
        FileUtils.rm_f sync_file unless env.dryrun?
        rm_rf(git_path)
        clean_done = true
      end

      fargs = if sync_file && File.exists?(sync_file) && !env.clean?
                "-newer '#{sync_file}'"
              else
                ""
              end
      fargs << " -maxdepth #{options[:maxdepth]}" unless options[:maxdepth].nil?
      mod_files = env.run_local %Q[find #{disc_path} #{fargs} -type f]
      mod_files.split("\n").each { |file|
        basename = File.basename(file)
        next if basename.start_with?('job.properties') ||
          basename.eql?("run.properties") ||
          basename.eql?(".DS_Store") ||
          basename.eql?(".bak") ||
          basename.eql?(".tmp") ||
          basename.eql?(".hdfs") ||
          basename.eql?("Rakefile") ||
          basename.end_with?(".sync") ||
          file.include?("migrations/") ||
          file.include?(".bak/") ||
          file.include?(".tmp/")
        put_file(file, already_cleaned: clean_done)
      }
    rescue StandardError => ex
      raise FailedToPutDir.new ex,
        msg: "Unable to write directory to HDFS.",
        ssh_user: env.ssh_user,
        path_on_disc: disc_path,
        path_on_github: git_path,
        path_on_hdfs: hdfs_path,
        sync_file: sync_file,
        max_depth: options[:maxdepth],
        clean: env.clean? ? "true" : "false"
    else
      env.run_local %Q[touch '#{sync_file}'] unless env.dryrun?
    ensure
      FileUtils.cd(original_pwd) if pushd
    end

    class FailedToGetFile < Hodor::NestedError; end

    # get
    #  Gets a file from HDFS and copies it to a local file
    def get_file(file, options = {})
      disc_path = env.path_on_disc(file)
      hdfs_path = path_on_hdfs(file)
      git_path = env.path_on_github(file)
      dest_path = "#{file}.hdfs_copy"

      logger.info "\tgetting '#{git_path}'. Writing to '#{dest_path}'."

      get_script = %Q["rm -f #{dest_path}; HADOOP_USER_NAME=#{user} hadoop fs -get #{hdfs_path} #{dest_path}"]
      env.ssh get_script, echo: true, echo_cmd: true
      if options[:clobber]
        FileUtils.rm_f dest_path
      end
      env.run_local %Q[scp #{env.ssh_user}@#{env[:ssh_host]}:#{dest_path} .],
        echo: true, echo_cmd: true
    rescue StandardError => ex
      raise FailedToGetFile.new ex,
        msg: "Unable to get file from HDFS.",
        ssh_user: env.ssh_user,
        path_on_disc: disc_path,
        path_on_github: git_path,
        path_on_hdfs: hdfs_path,
        dest_file: dest_file
    end
  end
end
