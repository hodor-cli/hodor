require_relative 'config_set'
require 'yaml'
module Hodor::Config
  class YmlConfigSet < ConfigSet

    def format_extension
      'yml'
    end

    def hash
      YAML.load(self.loader.load_text)
    end
  end
end