require 'erb'
require_relative 'util/yml_tools'

module Hodor
  class Configuration
    include YmlTools

    def env
      Environment.instance
    end

    def target
      env.settings[:target]
    end

    def logger
      env.logger
    end

    def initialize(yml_file)
      @yml_file = yml_file
      @kvp = {}
    end

    def load

      @loaded = true

      yml_expand(@target_cluster, [@clusters])
    end
  end
end

