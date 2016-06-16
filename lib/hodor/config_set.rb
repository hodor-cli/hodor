require 'erb'
require 'yaml'
require_relative 'config/source'

module Hodor
  class ConfigSet
    include YAML

    attr_accessor :config_name

    BASE_LOCAL_FILE_SPECIFICATION = { yml: { local: { folder: 'config'}}}

    LOAD_SETS_FILE_SPECIFICATION = BASE_LOCAL_FILE_SPECIFICATION.
                                    recursive_merge({ yml: { local: { config_file_name: 'load_sets' }}})

    def self.config_definitions_sets
      Hodor::Config::Source.new_source('load_sets', LOAD_SETS_FILE_SPECIFICATION)
    end

    def initialize(config_name)
      @config_name = config_name
    end

    def env
      Environment.instance
    end

    def target
      env.settings[:target]
    end

    def config_sets
      @config_sets ||= load
    end

    def config_defs
      @config_defs ||= if self.class.config_definitions_sets.config_hash.include? config_name.to_sym
                         self.class.config_definitions_sets.config_hash[config_name.to_sym]
                       else
                         [BASE_LOCAL_FILE_SPECIFICATION.
                             recursive_merge({ yml: { local: { config_file_name: config_name.to_s }}})]
                       end
    end

    def logger
      env.logger
    end

    def config_hash
      config_sets.each_with_object({}) { |in_configs, out_configs| out_configs.recursive_merge!(in_configs.config_hash)}

    end

    def process

    end

    def load
      out_set = []
      config_defs.each do |conf_def|
        set_name = "#{conf_def.keys.first}:#{config_name}"
        out_set << Hodor::Config::Source.new_source(set_name, conf_def)
      end
      out_set
    end

  end
end

