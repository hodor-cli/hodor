require_relative 'job'

module Hodor::Oozie

  class Workflow < Job

    attr_reader :json, :app_path, :acl, :status, :created_at, :conf, :last_mod_time, :run,
      :end_time, :external_id, :name, :app_name, :id, :start_time, :materialization_id, :parent_id,
      :materialization, :to_string, :group, :console_url, :user

    class << self
      def default_columns
        [:index, :id, :status, :created_at, :last_mod_time, :app_name]
      end
    end

    def initialize(json)
      super()
      @json = json

      @app_path = json["appPath"]
      @acl = json["acl"]
      @status = json["status"]
      @created_at = parse_time json["createdTime"]
      @conf = json["conf"]
      @last_mod_time = parse_time json["lastModTime"]
      @run = json["run"]
      @end_time = parse_time json["endTime"]
      @external_id = json["externalId"]
      @name = @app_name = json["appName"]
      @id = json["id"]
      @start_time = parse_time json["startTime"]
      @materialization_id = json["parentId"]
      ati = @materializeation_id.nil? ? nil : @materialization_id.index('@')
      if ati && ati > 0
        @parent_id = @materialization_id[0..ati-1]
      else
        @parent_id = @materialization_id
        @materialization = nil
      end

      @to_string = json["toString"]
      @group = json["group"]
      @console_url = json["consoleUrl"]
      @user = json["user"]
    end

    def expand
      # expand immediate children
      @actions = json["actions"].map do |item|
        require_relative 'action'
        Hodor::Oozie::Action.new(item)
      end.compact
    end

  end

end
