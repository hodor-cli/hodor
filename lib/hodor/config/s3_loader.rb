require_relative 'loader'
require 'aws-sdk'

module Hodor::Config
  class S3Loader < Loader
    attr_accessor :bucket
    def initialize(props, config_file_name, format_type='yml')
      super(props, config_file_name, format_type)
      @bucket =  props[:bucket]
    end

    def load
      s3 = Aws::S3::Client.new(region: 'us-east-1')
      object = s3.get_object(bucket: bucket, key: object_key)
      object.body.read
    end

    def object_key
      "#{properties[folder]/"#{config_file_name}.#{format_type}"}"
    end
  end
end