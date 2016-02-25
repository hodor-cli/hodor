module Hodor::Oozie

  class Bundle < Job

    attr_reader :status, :json

    class << self
      def default_columns
        [:index, :id, :status]
      end
    end

    def initialize(json)
      super()
      @json = json
      @status = json["status"]
    end

    def expand
      # Expand immediate children
      @coordinators = json["coords"].map do |item|
        Coordinator.new(item)
      end.compact
    end

  end
end
