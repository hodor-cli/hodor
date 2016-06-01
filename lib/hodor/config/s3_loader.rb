require_relative 'loader'
require 'aws-sdk'

module Hodor::Config
  class S3Loader < Loader
    def load
      bucket = Aws::S3::Bucket.new(properties[bucket])
      object = bucket.object(bucket)
      object.get(object_key).body.read
    end

    def object_key
      "#{properties[folder]/"#{config_file_name}.#{format_type}"}"
    end
  end
end