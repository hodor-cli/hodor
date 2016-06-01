require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/hash/keys'

module Hodor::Config
  class ConfigSet
    attr_accessor :properties
    def self.new_config_set(path_def)
      format_type = path_def.keys.first
      props = path_def[format_type].deep_symbolize_keys
      if [:yml, :edn].include? format_type.to_sym
        eval('Hodor::Config::' + "#{format_type.to_s.downcase}_config_set".camelize + '.new(props)')
        #self.send("#{key.to_s.downcase}_config".to_sym, props)
      else
        raise NotImplementedError.new("#{format_type.to_s.titleize} is not a supported format")
      end
    end

    def initialize(props)
      @properties = props
    end

    def loader
      valid_loader_types = [:s3, :local]
      return @loader unless @loader.nil?
      load_type = properties.slice(*valid_loader_types)
      if load_type.count == 1
        load_key = load_type.keys.first
        props=properties[load_key]
        eval('Hodor::Config::' + "#{load_key.to_s.downcase}_loader".camelize + '.new(props)')
      else
        raise "Invalid file loader definition must be one of #{valid_loader_types.join(', ')}"
      end
    end

    require_relative 'yml_config_set'
    require_relative 'edn_config_set'
    require_relative 'local_loader'
    require_relative 's3_loader'
  end
end