require_relative 'config_set'
require 'edn'
require 'active_support/core_ext/hash'

module Hodor::Config
  class EdnConfigSet < ConfigSet

    def format_extension
      'edn'
    end

    def hash
      EDN.read(loader.load_text).deep_symbolize_keys

    end
  end
end