require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/hash/keys'

module Hodor::Config
  class Loader
    attr_accessor :properties, :config_file_name, :format_type
    def initialize(props, config_file_name, format_type='yml')
      @properties = props
      @format_type = format_type.to_s
      @config_file_name = config_file_name
    end
  end
end