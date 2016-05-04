module Hodor::Oozie

  class Query < Job
    attr_reader :request, :json, :jobs, :filter

    def session
      Hodor::Oozie::Session.instance
    end

    class << self
      def suppress_properties
        true
      end
      def default_columns
        [:index, :name, :status, :id, :start_time, :time_unit, :external_id]
      end
    end

    def initialize(filter = {} )
      @filter = filter
      @jobtype = filter[:jobtype] || "coord"
      @json = run_query(filter)
      @request = session.last_query
    end

    def run_query(filter)
      params = []
      if filter.has_key?(:user)
        params << "user%3D#{filter[:user]}"
      end

      if filter.has_key?(:status)
        stats = filter[:status]
        params += stats.map { |val|
          case val
          when :running_first;
            @running_first = true
            "status%3DRUNNING"
          when :running; "status%3DRUNNING"
          when :killed; "status%3DKILLED"
          when :suspended; "status%3DSUSPENDED"
          when :timedout; "status%3DTIMEDOUT"
          when :failed; "status%3DFAILED"
          when :succeeded; "status%3DSUCCEEDED"
          end
        }
      end

      if params.size > 0
        filter_exp = "filter=#{params.join(';')}"
      else
        filter_exp = ""
      end

      pagination = []
      pagination << "offset=#{session.offset}"
      pagination << "len=#{session.len.to_i+1}"
      pagination = pagination.join('&')

      response = session.search_jobs("jobtype=#{@jobtype}", filter_exp, pagination)
      @json = JSON.parse(response)
    end

    def title
      if @jobtype.start_with?('coord')
        val = "List of Coordinators"
      elsif @jobtype.start_with?('w')
        val = "List of Workflows"
      elsif @jobtype.start_with?('b')
        val = "List of Bundles"
      else
        val = "List of Matching Jobs"
      end
      utc_time = display_as_time(Time.now.utc)
      local_time = Time.now.strftime("%H:%M %Z")
      ["#{session.hadoop_env.capitalize}: #{val}", "System Time: #{utc_time} / #{local_time}"]
    end

    def expand
      # expand immediate children
      if @json.has_key?("workflows")
        all_jobs = @json["workflows"].map do |item|
          Hodor::Oozie::Workflow.new(item)
        end.compact
        if @running_first
          more_json = run_query( { status: [:killed, :succeeded, :failed, :suspended] } )
          if more_json.has_key?("workflows")
            all_jobs += more_json["workflows"].map do |item|
              Hodor::Oozie::Workflow.new(item)
            end.compact
          end
        end
      elsif @json.has_key?("coordinatorjobs")
        all_jobs = @json["coordinatorjobs"].map do |item|
          Hodor::Oozie::Coordinator.new(item)
        end.compact
        if @running_first
          more_json = run_query( { status: [:succeeded, :killed, :failed, :suspended] } )
          if more_json.has_key?("coordinatorjobs")
            all_jobs += more_json["coordinatorjobs"].map do |item|
              Hodor::Oozie::Coordinator.new(item)
            end.compact
          end
        end
      end
      if @filter[:match]
        pattern = @filter[:match]
        @jobs = all_jobs.select { | job| 
          job.name.include?(pattern)
        }
      else
        @jobs = all_jobs
      end
      @jobs
    end

  end
end
