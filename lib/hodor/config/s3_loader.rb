require_relative 'loader'

module Hodor::Config
  class S3Loader < Loader
    attr_accessor :properties
    def initialize(props)
      @properties = props
    end
  end
end