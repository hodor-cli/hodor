require 'json'

module Hodor
  module Cli

    class Appendix < Thor

    end

    class Oozie < ::Hodor::Command
      no_tasks do

        def oozie
          ::Hodor::Oozie
        end

        def intercept_dispatch(command, trailing)
          case command
          when :jobs
            hadoop_command("oozie jobs", trailing)
          when :job
            hadoop_command("oozie job", trailing)
          end
        end

        def self.help(shell, subcommand = false)
          shell.print_wrapped(load_topic("overview"), indent: 0)
          result = super

          more_help = %Q[Getting More Help:
          ------------------
          To get detailed help on specific Oozie commands (i.e. display_job), run:

             $ hodor help oozie:display_job
             $ hodor oozie:help display_job    # alternate, works the same

          To view information on one of the Oozie topics (i.e. driver scenarios), run:

             $ hodor oozie:topic driver_scenarios

          And to see a list of Oozie topics that are available for display, run:

             $ hodor oozie:topics
          ].unindent(10)
          shell.say more_help
          result
        end
      end

      desc "jobs <arguments>", %q{
        Pass through command that executes its arguments on the remote master using 'oozie jobs <arguments>'
      }.gsub(/^\s+/, "").strip
      long_desc <<-LONGDESC
       Executes the 'oozie jobs' command on the remote master using SSH. The arguments
       passed to this command are pass through as-is to the SSH-based command-line.

       Example Usage:

       $ hodor oozie:jobs -oozie http://my.company.com:8080/oozie -localtime -len 2 -fliter status=RUNNING
      LONGDESC
      def jobs
        # handled by intercept_dispatch
      end

      desc "job <arguments>", %q{
        Pass through command that executes its arguments on the remote master using 'oozie job <arguments>'
      }.gsub(/^\s+/, "").strip
      long_desc <<-LONGDESC
       Executes the 'oozie job' command on the remote master using SSH. The arguments
       passed to this command are pass through as-is to the SSH-based command-line.

       Example Usage:

       $ hodor oozie:job -oozie http://my.company.com:8080/oozie -start 14-20090525161321-oozie-joe
      LONGDESC
      def job
        # handled by intercept_dispatch
      end

      desc "change_job [JOB PATH]", %q{
        Changes to a different job within the hierarhcy of Oozie jobs
      }.gsub(/^\s+/, "").strip
      long_desc %Q[
       The change_job command changes the "current_job" but does not display anything. Use
       the "display_job" command to display information about the job change_job
       just made current. The change_job command can of course take a job id as
       argument:
       \x5   $ hodor oozie:change_job 0004729-150629212824266-oozie-oozi-C

       However, other "special" arguments are also allowed:
       \x5   $ hodor oozie:change_job ..    # Change to parent of current job
           $ hodor oozie:change_job 3     # Change to the child with index 3
           $ hodor oozie:change_job /     # Change to list of topmost coordinators
                                          #    same as oozie:coordinators

       Suggested Alias:
       \x5   $ alias cj='hodor oozie:change_job'
      ].unindent(8)
      def change_job(*job_path)
        oozie.session.verbose = options[:verbose]
        oozie.session.len = options[:len] if options[:len]
        oozie.session.offset = options[:offset] if options[:offset]
        oozie.change_job(job_path[0])
      end

      desc "display_job [JOB PATH] [attribute] [options]", %q{
       Display information about the 'current' job within the Oozie hierarhcy of jobs
      }.gsub(/^\s+/, "").strip
      long_desc load_topic("display_job")
      method_option :query, type: :boolean, aliases: "-q", default: false,
        desc: "Only query the job for information, but do not change to it"
      method_option :verbose, type: :boolean, aliases: "-v",
        desc: "Display all available information"
      method_option :killed, type: :boolean, aliases: "-k",
        desc: "Only display killed coordinator materializations"
      method_option :succeded, type: :boolean, aliases: "-s",
        desc: "Only display succeeded coordinator materializations"
      method_option :len, type: :numeric, aliases: "-l", default: nil,
        desc: "number of matching workflows to display"
      method_option :offset, type: :numeric, aliases: "-o", default: 0,
        desc: "The coordinator to start with in listing matching workflows"
      method_option :match, type: :array, aliases: "-m", default: nil,
        desc: "Array of words to match in config properties keys and values"
      method_option :write, type: :string, aliases: "-w", default: nil,
        desc: "Name of file to write the output of this command into"
      def display_job(*args)
        oozie.session.len = options[:len] if options[:len]
        oozie.session.offset = options[:offset] if options[:offset]
        query_mode = options[:query] || env.prefs[:display_job_query_mode]
        job_id = "."
        aspect = "info"
        args.each { |arg|
          if arg =~ /^[0-9]{1,4}$/ || # Index form of job id
            arg =~ /^[0-9]{5,8}\-[0-9]{10,18}\-oozie/ ||  # Oozie form
            arg =~ /job_[0-9]{5,20}/ ||  # Hadoop mapred form
            arg.eql?('..') || arg.eql?('/')
            job_id = arg
          else
            aspect = arg
          end
        }

        if aspect.eql?("info")
          filter = []
          filter << :killed if options[:killed]
          filter << :succeeded if options[:succeeded]
          job = oozie.job_by_path(job_id, !query_mode, filter)
          table = ::Hodor::Table.new(job, options[:verbose], options[:match])
          doc = table.to_s
        else
          job = oozie.job_by_path(job_id, !query_mode)
        end

        if aspect.eql?("props") || aspect.eql?("conf")
          if options[:match]
            doc = job.conf_map.match(options[:match]).awesome_inspect(plain: !options[:write].nil?)
          else
            doc = job.conf_map.awesome_inspect(plain: !options[:write].nil?)
          end
        elsif aspect.eql?("log")
          doc = job.log
        elsif aspect.eql?("rest") || aspect.eql?("request") || aspect.eql?("call")
          say job.rest_call
        elsif aspect.eql?("json")
          json = job.json
          doc = "REST CALL = #{::Hodor::Oozie::Session.instance.last_query}"
          doc << ::JSON.pretty_generate(json)
        elsif aspect.eql?("def") || aspect.eql?("definition")
          doc = job.definition
        else
        end
        local_filename = options[:write]
        if !local_filename.nil?
          File.open(local_filename, 'w') {|f| f.write(doc) }
        else
          say doc
        end
      end

      desc "pwj", "Displays information about which job is 'current' within the hierarchy of Oozie jobs"
      def pwj
        say "Current Job ID: #{oozie.session.current_id || 'nil'}"
        say "Parent Job ID: #{oozie.session.parent_id || 'nil'}"
        say "Most Recent Job Query: #{oozie.session.root_query || 'nil'}"
      end

      desc "ssh_display_job [JOB_ID]", %q{
      Legacy version of display_job that is based on SSH, rather than REST
      }.gsub(/^\s+/, "").strip
      method_option :definition, type: :boolean, aliases: "-d",
        desc: "Display the definition of the specified job"
      method_option :info, type: :boolean, aliases: "-i",
        desc: "Display information about the specified job"
      method_option :log, type: :boolean, aliases: "-l",
        desc: "Display the log file for the specified job"
      method_option :configcontent, type: :boolean, aliases: "-c",
        desc: "Display the variable-expanded config for the specified job"
      def ssh_display_job(job_id)
        if job_id.start_with?('job_')
          hadoop_id = job_id.sub('job_','')
          trash = hadoop_id.index(/[^0-9_]/)
          hadoop_id = hadoop_id[0..trash-1] if trash
          env.ssh "mapred job -logs job_#{hadoop_id} attempt_#{hadoop_id}_m_000000_0",
            echo: true, echo_cmd: true
        else
          job_id.sub!(/-W.*$/, '-W') unless job_id.include?('-W@')
          if options[:definition]
            logger.info "DEFINITION:"
            env.ssh "oozie job -oozie :oozie_url -definition #{job_id}",
              echo: true, echo_cmd: true
          elsif options[:log]
            logger.info "LOG:"
            env.ssh "oozie job -oozie :oozie_url -log #{job_id}",
              echo: true, echo_cmd: true
          elsif options[:configcontent]
            logger.info "CONFIG:"
            env.ssh "oozie job -oozie :oozie_url -configcontent #{job_id}",
              echo: true, echo_cmd: true
          else
            logger.info "INFO:"
            env.ssh "oozie job -oozie :oozie_url -info #{job_id}",
              echo: true, echo_cmd: true
          end
        end
      end

      desc "deploy_job", "Deploy to hdfs the directories that this job depends on"
      method_option :dryrun, type: :boolean, aliases: "-d", default: false,
        desc: "Don't actually deploy the files, just show what would be deployed"
      method_option :clean, type: :boolean, aliases: "-c", default: false,
        desc: "Clean the hdfs target before deploying this directory"
      method_option :verbose, type: :boolean, aliases: "-v", default: false,
        desc: "Log verbose details about which files are deployed and to where"
      method_option :maxdepth, type: :string, aliases: "-m", default: nil,
        desc: "The maximum number of directories deep to copy to HDFS"
      long_desc %Q[
       The deploy_job command reads the contents of the jobs.yml file located
       in your current directory, and deploys the paths specified by in the
       driver's "deploy" key. For a fuller explanation, view the "jobs.yml"
       topic, as follows:
       \x5   $ hodor oozie:topic jobs.yml
      ].unindent(8)
      def deploy_job(*driver)
        oozie.deploy_job(driver.length > 0 ? driver[0] : nil, options[:clean])
      end

      desc "run_job", "Run an oozie job on the target hadoop cluster"
      long_desc %Q[
       The run_job command reads the contents of the jobs.yml file located
       in your current directory, composes a job.properties file and submits
       the indicated driver workflow for execution by Oozie. If a job.properties
       or job.properties.erb file is provided, that file will be used to interpolate property values.
       For a fuller explanation, view the "jobs.yml" topic, as follows:
       \x5   $ hodor oozie:topic jobs.yml
      ].unindent(8)
      method_option :dry_run, type: :boolean, aliases: "-d", default: false,
        desc: "Generate computed job.properties file without running or deploying associated job."
      method_option :file_name_prefix, type: :string, aliases: '-p', default: '',
                    desc: 'Add a prefix to job properties filename. This is primarily for use with :dry_run'
      def run_job(*args)
        outfile = oozie.run_job(args.length > 0 ? args[0] : nil, options[:dry_run], options[:file_name_prefix])
        logger.info "Dry run: the properties file is available for inspection at #{outfile}"  if options[:dry_run]
      end

      desc "kill_job [JOB_ID]", "Kill the oozie job with the specified job id"
      def kill_job(*job_path)
        job = oozie.job_by_path(job_path[0])
        env.ssh "oozie job -oozie :oozie_url -kill #{job.id}",
          echo: true, echo_cmd: true
      end

      desc "reauth", "Remove cached auth tokens (sometimes necessary after an oozie restart)"
      def reauth
        ssh_command nil, "rm .oozie-auth-token"
      end

      desc "workflows", "List most recently run workflows, most recent first"
      method_option :verbose, type: :boolean, aliases: "-v",
        desc: "Display all available information"
      method_option :running, type: :boolean, aliases: "-r",
        desc: "Display running workflows"
      method_option :killed, type: :boolean, aliases: "-k",
        desc: "Display killed workflows"
      method_option :succeeded, type: :boolean, aliases: "-s",
        desc: "Display succeeded workflows"
      method_option :failed, type: :boolean, aliases: "-f",
        desc: "Display failed workflows"
      method_option :timedout, type: :boolean, aliases: "-t",
        desc: "Display timedout workflows"
      method_option :suspended, type: :boolean, aliases: "-p",
        desc: "Display suspended workflows"
      method_option :len, type: :numeric, aliases: "-l", default: 30,
        desc: "number of matching workflows to display"
      method_option :offset, type: :numeric, aliases: "-o", default: 0,
        desc: "The coordinator to start with in listing matching workflows"
      method_option :match, type: :string, aliases: "-m",
        desc: "Only display workflows that contain the given string as a substring"
      long_desc %Q[
       The workflows command uses its options to create a REST query for workflows
       that match your specification, and presents the results formated as a table.

       Examples:
       \x5  $ hodor oozie:workflows                 # displays most recent workflows
          $ hodor oozie:workflows -v              # same as before, but verbose
          $ hodor oozie:workflows -r              # displays running workflows
          $ hodor oozie:workflows -r -s -k        # running, succeeded or killed
          $ hodor oozie:workflows -l 30 -o 30     # display second 30 most recent
          $ hodor oozie:workflows -m data_source       # display only matching workflows
      ].unindent(8)
      def workflows
        oozie.session.verbose = options[:verbose]
        filter = {}
        filter[:jobtype] = "wf"
        filter[:status] = []
        filter[:status] << :running if options[:running]
        filter[:status] << :killed if options[:killed]
        filter[:status] << :succeeded if options[:succeeded]
        filter[:status] << :failed if options[:failed]
        filter[:status] << :timedout if options[:timedout]
        filter[:status] << :suspended if options[:suspended]
        filter[:status] << :running_first if filter[:status].empty?
        filter[:match] = options[:match] if options[:match]

        oozie.session.len = options[:len] if options[:len]
        oozie.session.offset = options[:offset] if options[:offset]

        result = ::Hodor::Oozie::Query.new(filter)
        table = ::Hodor::Table.new(result, options[:verbose])
        oozie.session.make_current(result)
        say table
      end

      desc "coordinators", "List most recently run coordinators, most recent first"
      method_option :verbose, type: :boolean, aliases: "-v",
        desc: "Display all available information"
      method_option :running, type: :boolean, aliases: "-r",
        desc: "Display running coordinators"
      method_option :killed, type: :boolean, aliases: "-k",
        desc: "Display killed coordinators"
      method_option :succeeded, type: :boolean, aliases: "-s",
        desc: "Display succeeded coordinators"
      method_option :failed, type: :boolean, aliases: "-f",
        desc: "Display failed coordinators"
      method_option :timedout, type: :boolean, aliases: "-t",
        desc: "Display timedout coordinators"
      method_option :suspended, type: :boolean, aliases: "-p",
        desc: "Display suspended coordinators"
      method_option :len, type: :numeric, aliases: "-l", default: 30,
        desc: "number of matching coordinators to display"
      method_option :offset, type: :numeric, aliases: "-o", default: 0,
        desc: "The coordinator to start with in listing matching coordinators"
      method_option :match, type: :string, aliases: "-m",
        desc: "Only display coordinators that contain the given string as a substring"
      long_desc %Q[
       The coordinators command uses its options to create a REST query for coordinators
       that match your specification, and presents the results formated as a table.

       Examples:
       \x5  $ hodor oozie:coordinators                 # displays most recent coordinators
          $ hodor oozie:coordinators -v              # same as before, but verbose
          $ hodor oozie:coordinators -r              # displays running coordinators
          $ hodor oozie:coordinators -r -s -k        # running, succeeded or killed
          $ hodor oozie:coordinators -l 30 -o 30     # display second 30 most recent
          $ hodor oozie:coordinators -m data_source       # display only matching coordinators
      ].unindent(8)
      def coordinators
        oozie.session.verbose = options[:verbose]
        filter = {}
        filter[:jobtype] = "coord"
        filter[:status] = []
        filter[:status] << :running if options[:running]
        filter[:status] << :killed if options[:killed]
        filter[:status] << :succeeded if options[:succeeded]
        filter[:status] << :failed if options[:failed]
        filter[:status] << :timedout if options[:timedout]
        filter[:status] << :suspended if options[:suspended]
        filter[:status] << :running_first if filter[:status].empty?
        filter[:match] = options[:match] if options[:match]

        oozie.session.len = options[:len] if options[:len]
        oozie.session.offset = options[:offset] if options[:offset]

        result = ::Hodor::Oozie::Query.new(filter)
        table = ::Hodor::Table.new(result, options[:verbose])
        oozie.session.make_current(result)
        say table
      end

      desc "bundles", "List most recently run bundles, most recent first"
      method_option :len, type: :numeric, aliases: "-l", default: 2,
        desc: "number of recent bundles to display"
      def bundles
        env.ssh "oozie:jobs -oozie :oozie_url -jobtype bundle -len #{options[:len]}",
          echo: true, echo_cmd: true
      end

    end
  end
end
