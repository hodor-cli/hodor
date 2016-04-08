module Hodor::Oozie

  class HadoopJob < Job

    attr_reader :id, :parent_id, :rest_call

    class << self
      def default_columns
        [:index, :id]
      end
    end

    def initialize(parent_id, job_id)
      super()
      @id = job_id
      @parent_id = parent_id
      session.verbose = true # force verbosity for hadoop jobs
    end

    def log
      hadoop_id = @id.sub('job_','')
      trash = hadoop_id.index(/[^0-9_]/)
      hadoop_id = hadoop_id[0..trash-1] if trash
      session.env.ssh "mapred job -logs job_#{hadoop_id} attempt_#{hadoop_id}_m_000000_0"
    end

  end

end
