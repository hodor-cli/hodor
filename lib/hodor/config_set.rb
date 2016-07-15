require 'hodor'
require 'erb'
require 'yaml'
require_relative 'config/source'
require_relative 'config/yml_source'
require_relative 'config/edn_source'

module Hodor
  class ConfigSet
    include YAML

    attr_accessor :config_name

    BASE_LOCAL_FILE_SPECIFICATION = { yml: { local: { folder: 'config'}}}

    LOAD_SETS_FILE_SPECIFICATION = BASE_LOCAL_FILE_SPECIFICATION.
                                    recursive_merge({ yml: { local: { config_file_name: 'load_sets' }}})

    REQUIRED_TAG = "#required"

    DEFAULT_ACTION_ON_REQUIRED_MISSING = :warn

    def self.config_definitions_sets
      @@config_definition_sets ||= Hodor::Config::YmlSource.new('load_sets', LOAD_SETS_FILE_SPECIFICATION[:yml])
    end

    def self.has_required_tag?(val)
      val.is_a?(String) && val.start_with?(REQUIRED_TAG)
    end

    def self.logger
      @@logger = Environment.instance.logger
    end

    def self.check_for_missing_configs(tst_hash, on_required_missing_do=:warn)
      missing_properties = []
      missing_configs(missing_properties, tst_hash)
      unless missing_properties.empty?
        raise self.missing_properties_error(missing_properties)  if on_required_missing_do == :fail
        logger.warn( self.missing_properties_error(missing_properties) ) if on_required_missing_do == :warn
      end
    end

    def self.missing_properties_error(missing_properties)
      messages =  missing_properties.map{ |pair| "#{pair[0]} #{pair[1]}"}
      "Missing properties: #{ messages.join('; ') }."
    end

    def self.missing_configs(missing_config_props, configs)
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

    def on_required_missing
      load_source_info if @on_required_missing.nil?
      @on_required_missing
    end

    def config_defs
      load_source_info unless @config_defs
      @config_defs
    end

    def load_source_info
      if @config_defs.nil? || @check_required.nil?
        if self.class.config_definitions_sets.config_hash.include? config_name.to_sym
          full_definition = self.class.config_definitions_sets.config_hash[config_name.to_sym]
          @config_defs, @on_required_missing = full_definition[:sources],
                                               full_definition[:on_required_missing]
        else
          logger.warn("There is no config definition set for #{config_name.to_s} " +
                          "defined in config/load_sets.yml. Hodor will look for the file " +
                          "in the default location: config/#{config_name.to_s}.yml")
          @config_defs, @on_required_missing = [BASE_LOCAL_FILE_SPECIFICATION.recursive_merge(
                                                    { yml: { local: { config_file_name: config_name.to_s }}})],
                                                DEFAULT_ACTION_ON_REQUIRED_MISSING
        end
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
      Hodor::ConfigSet.check_for_missing_configs(raw_hash, on_required_missing)

      raw_hash
    end

    def load
      out_set = []
      config_defs.each do |conf_def|
        set_name = "#{conf_def.keys.first}:#{config_name}"
        out_set << load_config_source(set_name, conf_def)
      end
      out_set
    end

    def load_config_source(set_name, path_def)
      format_type = path_def.keys.first
      props = path_def[format_type].deep_symbolize_keys
      if [:yml, :edn].include? format_type.to_sym
        eval_string = 'Hodor::Config::' + "#{format_type.to_s.downcase}_source".camelize + '.new(set_name, props)'
        eval(eval_string)
      else
        raise NotImplementedError.new("#{format_type.to_s.titleize} is not a supported format")
      end
    end
  end
end

