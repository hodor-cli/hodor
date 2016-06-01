require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/hash/keys'

module Hodor::Config
  class Loader
    attr_accessor :properties
    def initialize(props)
      @properties = props
    end
  end
end