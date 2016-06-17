#require_relative 'source'
require 'edn'
require 'active_support/core_ext/hash'

module Hodor::Config
  class EdnSource < Source

    def format_extension
      'edn'
    end

    def config_hash
      return {} unless loader.load_text
      EDN.read(loader.load_text).deep_symbolize_keys
    end
  end
end