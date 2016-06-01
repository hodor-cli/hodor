require 'active_support/core_ext/string'
module Hodor::Config
  class ConfigSet
    def self.new_config_set(path_def)
      format_type = path_def.keys.first
      props = path_def[format_type]
      if [:yml, :edn].include? format_type.to_sym
        eval('Hodor::Config::' + "#{format_type.to_s.downcase}_config_set".camelize + '.new(props)')
        #self.send("#{key.to_s.downcase}_config".to_sym, props)
      else
        raise NotImplementedError.new("#{format_type.to_s.titleize} is not a supported format")
      end
    end
    require_relative 'yml_config_set'
    require_relative 'edn_config_set'
  end
end