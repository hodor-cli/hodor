module Hodor::Oozie

  class Coordinator < Job

    attr_reader :id, :json, :name, :path, :timezone, :frequency, :conf, :end_time, :execution_policy, :start_time, :time_unit,
        :concurrency, :id, :last_action, :acl, :mat_throttling, :timeout, :next_materialized_time, :parent_id,
        :external_id, :group, :user, :console_url, :actions, :acl, :status, :materializations

    class << self
      def default_columns
        [:index, :id, :name, :status, :start_time, :time_unit, :external_id]
      end
    end

    def initialize(json)
      super()
      @json = json
      @name = json["coordJobName"]
      @path = json["coordJobPath"]
      @timezone = json["timeZone"]
      @frequency = json["frequency"]
      @conf = json["conf"]
      @end_time = parse_time(json["endTime"])
      @execution_policy = json["executionPolicy"]
      @start_time = parse_time(json["startTime"])
      @time_unit = json["timeUnit"]
      @concurrency = json["concurrency"]
      @id = json["coordJobId"]
      @last_action = parse_time(json["lastAction"])
      @acl = json["acl"]
      @mat_throttling = json["mat_throttling"]
      @timeout = json["timeOut"]
      @next_materialized_time = parse_time(json["nextMaterializedTime"])
      @parent_id = @bundle_id = json["bundleId"]
      @external_id = json["coordExternalId"]
      @group = json["group"]
      @user = json["user"]
      @console_url = json["consoleUrl"]
      @actions = json["actions"]
      @acl = json["acl"]
      @status = json["status"]
    end

    def expand
      # Expand immediate children
      @materializations = json["actions"].map do |item|
        Materialization.new(item)
      end.compact.reverse
      @materializations
    end

  end
end
