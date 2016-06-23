require 'hodor'
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

    REQUIRED_TAG = "#required"

    def self.config_definitions_sets
      @@config_definition_sets ||= Hodor::Config::Source.new_source('load_sets', LOAD_SETS_FILE_SPECIFICATION)
    end

    def initialize(config_name)
      @config_name = config_name
    end


    def env
      Environment.instance
    end

    def logger
      env.logger
    end

    def config_sets
      @config_sets ||= load
    end

    def config_defs
      @config_defs ||= if self.class.config_definitions_sets.config_hash.include? config_name.to_sym
                         self.class.config_definitions_sets.config_hash[config_name.to_sym]
                       else
                         logger.warn("There is no config definition set for #{config_name.to_s} " +
                               "defined in config/load_sets.yml. Hodor will look for the file " +
                               "in the default location: config/#{config_name.to_s}.yml")
                         [BASE_LOCAL_FILE_SPECIFICATION.
                             recursive_merge({ yml: { local: { config_file_name: config_name.to_s }}})]
                       end
    end

    def logger
      env.logger
    end

    def config_hash
      @config_hash ||= process
    end

    def process
      raw_hash = config_sets.each_with_object({}) { |in_configs, out_configs|
                                                    out_configs.recursive_merge!(in_configs.config_hash)}
      missing_properties = []
      missing_configs(missing_properties, raw_hash)
      raise missing_properties_error(missing_properties) unless missing_properties.empty?
      raw_hash
    end

    def missing_properties_error(missing_properties)
       messages =  missing_properties.map{ |pair| "#{pair[0]}, #{pair[1]}"}
      "Missing properties: #{ messages.join('; ') }."
    end

    def missing_configs(missing_config_props, configs)
      configs.each_pair do |key, val|
        if val.is_a?(Hash)
          missing_configs(missing_config_props, val)
        elsif val.is_a?(Array)
          val.each do |element|
            if val.is_a?(Hash)
              missing_configs(missing_config_props, val)
            elsif val.is_a?(Array)
              raise "Configurations cannot contain multidimensional arrays"
            else
              missing_config_props << [key, val] if has_required_tag?(val)
            end
          end
        else
          missing_config_props << [key, val] if has_required_tag?(val)
        end
      end
    end

    def has_required_tag?(val)
      val.is_a?(String) && val.start_with?(REQUIRED_TAG)
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

