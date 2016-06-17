#require 'active_support/core_ext/string'
#require 'active_support/core_ext/hash'
#require 'active_support/core_ext/hash/keys'
require_relative '../environment'

module Hodor::Config
  class Loader
    attr_accessor :properties, :config_file_name, :format_suffix
    def initialize(props, format_suffix='yml')
      @properties = props
      @format_suffix = format_suffix.to_s
      @config_file_name = props[:config_file_name]
      unless @properties &&  @config_file_name
        raise "Missing load configs. Input: properties=#{@properties} and filename=#{@config_file_name} ."
      end
    end

    def logger
      env.logger
    end

    def env
      Hodor::Environment.instance
    end
  end
end