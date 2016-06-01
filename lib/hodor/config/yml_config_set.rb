require_relative 'config_set'
module Hodor::Config
  class YmlConfigSet < ConfigSet

    def format_extension
      'yml'
    end
  end
end