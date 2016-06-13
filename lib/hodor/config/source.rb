require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'

module Hodor::Config
  class Source
    attr_accessor :properties, :defaults, :name, :loader
    def self.new_source(name, path_def)
      format_type = path_def.keys.first
      props = path_def[format_type].deep_symbolize_keys
      if [:yml, :edn].include? format_type.to_sym
        eval_string = 'Hodor::Config::' + "#{format_type.to_s.downcase}_source".camelize + '.new(name, props)'
        eval(eval_string)
      else
        raise NotImplementedError.new("#{format_type.to_s.titleize} is not a supported format")
      end
    end

    def initialize(name, props)
      @properties = props
      @defaults = defaults
      @name = name
    end

    def format_extension
      'invalid'
    end

    def loader
      valid_loader_types = [:s3, :local]
      return @loader unless @loader.nil?
      load_type = properties.slice(*valid_loader_types)
      if load_type.count == 1
        load_key = load_type.keys.first
        props = properties[load_key]
        eval_string = 'Hodor::Config::' + "#{load_key.to_s.downcase}_loader".camelize + '.new(props, format_extension)'
        @loader = eval(eval_string)
      else
        raise "Invalid file loader definition must be one of #{valid_loader_types.join(', ')}"
      end
    end

    require_relative 'yml_source'
    require_relative 'edn_source'
    require_relative 'local_loader'
    require_relative 's3_loader'
  end
end