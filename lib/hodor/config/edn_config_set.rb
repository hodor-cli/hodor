require_relative 'config_set'
module Hodor::Config
  class EdnConfigSet < ConfigSet

    def format_extension
      'edn'
    end
  end
end