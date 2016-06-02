require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/hash/keys'

module Hodor::Config
  class Loader
    attr_accessor :properties, :config_file_name, :format_suffix
    def initialize(props, config_file_name, format_suffix='yml')
      @properties = props
      @format_suffix = format_suffix.to_s
      @config_file_name = config_file_name
      unless @properties &&  @config_file_name
        raise "Missing load configs. Input: properties=#{@properties} and filename=#{config_file_name} ."
      end
    end

    def load
      raise "This is a base class for loader so it does not implement load."
    end
  end
end