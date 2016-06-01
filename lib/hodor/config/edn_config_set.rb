require_relative 'config_set'
module Hodor::Config
  class EdnConfigSet < ConfigSet
    def initialize(params)
      puts "IN EDN: #{params}"
    end
  end
end