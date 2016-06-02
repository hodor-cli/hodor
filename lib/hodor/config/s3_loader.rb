require_relative 'loader'
require 'aws-sdk'

module Hodor::Config
  class S3Loader < Loader
    attr_accessor :bucket, :folder
    def initialize(props, config_file_name, format_suffix='yml')
      super(props, config_file_name, format_suffix)
      @bucket =  props[:bucket]
      @folder =  props[:folder]
      unless @bucket &&  @folder
        raise "Missing S3 load configs: bucket=#{@bucket} and folder=#{@folder} ."
      end
    end

    def s3
      Aws::S3::Client.new
    end

    def load
      object = s3.get_object(bucket: bucket, key: object_key)
      object.body.read
    end

    def object_key
      "#{folder}/#{config_file_name}.#{format_suffix}"
    end
  end
end