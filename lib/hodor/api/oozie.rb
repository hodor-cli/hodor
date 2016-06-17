require_relative "oozie/job"
require_relative "oozie/query"
require_relative "oozie/session"
require_relative "oozie/bundle"
require_relative "oozie/coordinator"
require_relative "oozie/materialization"
require_relative "oozie/workflow"
require_relative "oozie/action"
require_relative "oozie/hadoop_job"
require_relative "hdfs"

module Hodor::Oozie

    class << self

      def env
        Hodor::Environment.instance
      end

      def session
        Hodor::Oozie::Session.instance
      end

      def hdfs
        Hodor::Hdfs.instance
      end

      def logger
        env.logger
      end

      def build_rest_param(filter)
        params = filter.map { |match|
          case match
          when :killed; "status%3DKILLED"
          when :succeeded; "status%3DSUCCEEDED"
          end
        }

        if params.size > 0
          filter_exp = "filter=#{params.join(';')}"
        else
          filter_exp = ""
        end
      end

      def job_by_id(job_id, filter = nil)
        if (job_id.nil?)
          result = Hodor::Oozie::Query.new status: [:running_first]
        else
          if job_id =~ /job_\d+/
            result = HadoopJob.new(session.current_id, job_id)
          else
            if filter
              response = session.get_job_state(job_id, build_rest_param(filter))
            else
              response = session.get_job_state(job_id)
            end
            json = JSON.parse(response)
            job_type = json["toString"]
            case job_type.split(" ").first.downcase.to_sym
            when :bundle;
              result = Bundle.new(json)
            when :coordinator;
              result = Coordinator.new(json)
            when :workflow;
              result = Workflow.new(json)
            when :action;
              result = Action.new(json)
            when :coordinatoraction;
              result = Materialization.new(json)
            else
            end
          end
        end
      end

      def job_by_path(job_path, make_current = false, filter = nil)
        if job_path.nil? || job_path.eql?(".")
          movement = :none
        elsif job_path.eql?("/")
          movement = :root
        elsif job_path.eql?("b") || job_path.eql?("back") || 
          job_path.eql?("u") || job_path.eql?("up") || job_path.eql?("..")
          movement = :up
        elsif job_path.eql?("d") || job_path.eql?("down") || 
          job_path.eql?("f") || job_path.eql?("forward") || job_path.length < 5
          movement = :down
        else
          movement = :jump
        end

        job_id = session.job_relative(movement, job_path)
        job = job_by_id(job_id, filter)
        session.make_current(job) if make_current
        job
      end

      def change_job(job_path, filter = nil)
        job_by_path(job_path, true, filter)
      end

      def select_job(job)
        if job && (job =~ /job.properties.erb$/ || job =~ /job.properties/)
          selected_job = { dirname: File.dirname(job), basename: File.basename(job), file: job, display_name: job }
        else
          # load jobs.yml file
          pwd = Dir.pwd
          if File.exists?("jobs.yml")
            jobs = env.yml_load(File.expand_path('jobs.yml', pwd))
            marked_jobs = jobs.keys.select { |key| key.start_with?('^') }
            marked_jobs.each { |mark|
              jobs[mark[1..-1]] = jobs[mark]
            }
            if job.nil?
              # No job explicitly specified, so look for a
              # marked job (i.e. job starting with ^)
              jobs.each_pair { |key, val|
                if key.to_s.strip.start_with?('^')
                  job = key.to_s
                end
              }
              fail "You must specify which job from jobs.yml to run" if !job
            end
            jobs = jobs.symbolize_keys
            if !jobs.has_key?(job.to_sym)
              caret = "^#{job.to_s}"
              fail "Job '#{job}' was not defined in jobs.yml" if !jobs.has_key?(caret.to_sym)
            end
            selected_job = jobs[job.to_sym]
            selected_job[:name] = selected_job[:display_name] = job
          else
            fail "No jobs.yml file exists in the current directory. You must specify a jobs.yml file"
          end
        end
        env.select_job(selected_job)
      end

      # collect all job.properties.erb files up to root of repo
      # and compose them together in top down order (i.e. deeper
      # directories override properties in higher directories.)
      # If direct job properties file is provided, properties will
      # be interpolated using values in that file.
      def compose_job_file(job, options = {})
        pwd = Dir.pwd
        if job.has_key?(:file)
          raise "Job file '#{job[:file]}' not found" unless File.exists?(job[:file])
          src_job_file = File.expand_path(File.join(job[:dirname], '.tmp', job[:basename]), pwd)
          FileUtils.mkdir File.dirname(src_job_file) unless Dir.exists?(File.dirname(src_job_file))
          FileUtils.cp(job[:file], src_job_file)
        elsif job.has_key?(:name)
          paths = env.paths_from_root(pwd)
          composite_jobfile = paths.inject('') { |result, path|
            jobfile = File.expand_path('job.properties.erb', path)
            if File.exists?(jobfile)
              result << "\nFrom Job File '#{jobfile}':\n"
              result << File.read(jobfile)
            end
            result
          }
          FileUtils.mkdir './.tmp' unless Dir.exists?('./.tmp')
          src_job_file = File.expand_path(".tmp/runjob.properties.erb", pwd)
          File.open(src_job_file, "w") do |f|
            f.puts composite_jobfile
          end
        else
          logger.error "Unknown job type: #{job.inspect}"
        end
        job_file = src_job_file.sub(/\.erb$/,'')
        generate_and_write_job_file(job_file, src_job_file, job, options)
      end

      def generate_and_write_job_file(file_name, in_file, job, options = {})
        prefix = options[:file_prefix] || ''
        out_file = append_prefix_to_filename(file_name, prefix)
        job_content = env.erb_load(in_file) || ''
        job_props = options.inject('') { |accumulator, kvp|
          case kvp[0].to_sym
          when :file_prefix, :file_name_prefix, :dry_run;
          else
            accumulator += "#{kvp[0]} = #{kvp[1]}\n"
          end
          accumulator
        }
        unless job_props.empty?
          overrides = "\n# Property Overrides\n# ====================\n" + job_props
          job_content += overrides
        end
        File.open(out_file, 'w') { |f| f.write(job_content) } unless in_file.eql?(out_file)
        job[:overrides] = job_props
        job[:executable] = out_file
        out_file
      end

      def append_prefix_to_filename(file_name, prefix = '')
        insert_index =  file_name.rindex(File::SEPARATOR)
        String.new(file_name).insert((insert_index.nil? ? 0 : insert_index+1) , prefix)
      end

      def deploy_job(job, clean_deploy)
        select_job(job)
        fail "No deploy section for job '#{job}'." if !env.job.has_key?("deploy")
        if env.job[:deploy].nil?
          fail "Nothing to deploy. Check the deploy section of your jobs.yml file"
        else
          env.job[:deploy].split.each { |path|
            hdfs.put_dir File.expand_path(path, env.root), { clean: clean_deploy }
          }
        end
      end

      # If job references a job.properties or job.properties.erb file, that file will be
      # used directly to interpolate job property values.
      def run_job(job = nil, options = {})
        jobfile = compose_job_file(select_job(job), options)
        unless options[:dry_run]
          job = env.job
          logger.info "RUN JOB: #{job[:display_name]}"
          if job.has_key?(:overrides)
            logger.info "Propery Overrides:"
            job[:overrides].each_line { |line|
              logger.info "    #{line.strip}"
            }
          end
          runfile = env.deploy_tmp_file(jobfile)
          env.ssh "oozie job -oozie :oozie_url -config #{runfile} -run", echo: true, echo_cmd: true
        end
        jobfile
      end
    end
end
