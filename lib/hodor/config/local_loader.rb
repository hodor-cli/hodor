require_relative 'loader'
require_relative '../environment'

module Hodor::Config
  #include Hodor::Environment
  class LocalLoader < Loader
    attr_accessor  :folder
    def initialize(props, format_suffix='yml')
      super(props, format_suffix)
      @folder =  props[:folder]
    end

    def root
      Hodor::Environment.instance.root
    end

    def file_path
      "#{folder}/#{config_file_name}.#{format_suffix}"
    end

    def exists?
      File.exists?(absolute_file_path)
    end

    def load_text
      if exists?
         File.read(absolute_file_path)
      else
        raise "No file at: #{absolute_file_path}."
      end
    end

    def absolute_file_path
      "#{root}/#{file_path}"
    end
  end
end