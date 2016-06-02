require_relative 'config_set'
require 'edn'
module Hodor::Config
  class EdnConfigSet < ConfigSet

    def format_extension
      'edn'
    end

    def hash
      EDN.read(self.loader.load_text)
    end
  end
end