#require_relative 'source'
require 'yaml'
require 'active_support/core_ext/hash'

module Hodor::Config
  class YmlSource < Source

    def format_extension
      'yml'
    end

    def config_hash
      YAML.load(self.loader.load_text).deep_symbolize_keys
    end
  end
end