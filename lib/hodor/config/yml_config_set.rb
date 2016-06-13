require_relative 'config_set'
require 'yaml'
require 'active_support/core_ext/hash'

module Hodor::Config
  class YmlConfigSet < ConfigSet

    def format_extension
      'yml'
    end

    def hash
      YAML.load(self.loader.load_text).deep_symbolize_keys
    end
  end
end