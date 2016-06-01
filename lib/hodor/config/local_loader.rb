require_relative 'loader'

module Hodor::Config
  class LocalLoader < Loader
    attr_accessor :properties
    def initialize(props)
      @properties = props
    end
  end
end