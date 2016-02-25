module Hodor::Oozie

  class Action < Job

    attr_reader :parent_id, :json, :status, :error_message, :data, :transition, :external_status, :cred,
          :type, :end_time, :external_id, :start_time, :external_child_ids, :name, :error_code,
          :tracker_url, :retries, :to_string, :console_url

    class << self
      def default_columns
        [:index, :id, :name, :status, :created_at, :nominal_time]
      end
    end

    def initialize(json)
      super()
      @json = json

      @error_message = json["errorMessage"]
      @status = json["status"]
      @stats = json["stats"]
      @data = json["data"]
      @transition = json["transition"]
      @external_status = json["externalStatus"]
      @cred = json["cred"]
      @conf = json["conf"]
      @type = json["type"]
      @end_time = parse_time json["endTime"]
      @external_id = json["externalId"]
      @id = json["id"]
      @start_time = parse_time json["startTime"]
      @external_child_ids = json["externalChildIDs"]
      @name = json["name"]
      @error_code = json["errorCode"]
      @tracker_url = json["trackerUri"]
      @retries = json["retries"]
      @to_string = json["toString"]
      @console_url = json["consoleUrl"]
      @parent_id = @id[0..@id.index('@')-1]
    end

    def expand
      if @external_id && !@external_id.eql?('-')
        [ oozie.job_by_id(@external_id) ]
      else
        nil
      end
    end

  end

end
