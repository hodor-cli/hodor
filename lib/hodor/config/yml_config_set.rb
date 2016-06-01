require_relative 'config_set'
module Hodor::Config
  class YmlConfigSet < ConfigSet
    def initialize(params)
      puts "IN YML: #{params}"
    end
  end
end