module Hodor::Oozie

  class Materialization < Job

    attr_reader :json, :error_message, :last_modified_time, :created_at, :status, :push_missing_dependencies,
      :external_status, :type, :nominal_time, :external_id, :created_conf, :missing_dependencies,
      :run_conf, :action_number, :error_code, :tracker_uri, :to_string, :parent_id, :coord_job_id,
      :console_url

    class << self
      def default_properties
        [ :error_message, :last_modified_time, :created_at, :status, :push_missing_dependencies,
          :external_status, :type, :nominal_time, :external_id, :created_conf, :missing_dependencies,
          :run_conf, :action_number, :error_code, :tracker_uri, :to_string, :parent_id, :coord_job_id,
          :console_url]
      end

      def default_columns
        [:index, :id, :status, :external_id, :type, :created_at, :nominal_time, :last_modified]
      end
    end

    def initialize(json)
      super()
      @json = json
      @error_message = json["errorMessage"]
      @last_modified = @last_modified_time = parse_time(json["lastModifiedTime"])
      @created_at = parse_time(json["createdTime"])
      @status = json["status"]
      @push_missing_dependencies = json["pushMissingDependencies"]
      @external_status = json["externalStatus"]
      @type = json["type"]
      @nominal_time = parse_time(json["nominalTime"])
      @external_id = json["externalId"]
      @id = json["id"]
      @created_conf = json["createdConf"]
      @missing_dependencies = json["missingDependencies"]
      @run_conf = json["runConf"]
      @action_number = json["actionNumber"]
      @error_code = json["errorCode"]
      @tracker_uri = json["trackerUri"]
      @to_string = json["toString"]
      @parent_id = @coord_job_id = json["coordJobId"]
      @console_url = json["consoleUrl"]
    end

    def expand
      [ oozie.job_by_id(@external_id) ]
    end

    def display_id
      @id[@id.rindex('C@')..-1]
    end
  end

end
