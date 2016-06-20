require_relative 'loader'
require 'aws-sdk'

module Hodor::Config
  class S3Loader < Loader
    attr_accessor :bucket, :folder
    def initialize(props, format_suffix = 'yml')
      super(props, format_suffix)
      @bucket =  props[:bucket]
      @folder =  props[:folder]
      unless ENV['AWS_SECRET_ACCESS_KEY'] && ENV['AWS_REGION'] && ENV['AWS_ACCESS_KEY_ID']
        raise "AWS connection configuration missing from your environment:" +
                    " AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']}" +
                    " AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY}']}" +
                    " AWS_REGION=#{ENV['AWS_REGION']}"
      end
      unless @bucket &&  @folder
        raise "Missing S3 load configs: bucket=#{@bucket} and folder=#{@folder} ."
      end
    end

    def s3
      Aws::S3::Client.new
    end

    def load_text
      object = s3.get_object(bucket: bucket, key: object_key)
      if object.nil? || object.body.nil?
        logger.warn("No file on S3 at: #{bucket}/#{object_key}")
        nil
      else
        object.body.read
      end
    end

    def object_key
      "#{folder}/#{config_file_name}.#{format_suffix}"
    end
  end
end