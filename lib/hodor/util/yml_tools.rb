require 'yaml'
require_relative 'erb_tools'

module Hodor::Util
  module YmlTools
    include ErbTools

    def yml_load(filename) #, suppress_erb=false)
      YAML.load(erb_load(filename, false)) # suppress_erb))
    end

    def yml_expand(val, parents)
      if val.is_a? String
        val.gsub(/\$\{.+?\}/) do |match|
          cv = match.split(/\${|}/)
          expr = cv[1]
          ups = expr.split('^')
          parent_index = parents.length - ups.length
          parent = parents[parent_index]
          parent_key = ups[-1]
          parent_key = parent_key[1..-1] if parent_key.start_with?(':')
          if parent.has_key?(parent_key)
            parent[parent_key]
          elsif parent.has_key?(parent_key.to_sym)
            parent[parent_key.to_sym]
          else
            parent_key
          end
        end
      elsif val.is_a? Hash
        more_parents = parents << val
        val.each_pair do |k, v|
          exp_val = yml_expand(v, more_parents)
          val[k] = exp_val
        end
      else
        val
      end
    end

    def yml_flatten(parent_key, val)
      flat_vals = []
      if val.is_a? Hash
        val.each_pair { |k, v|
          flat_vals += yml_flatten("#{parent_key}.#{k}", v)
        }
      else
        parent_key = parent_key[1..-1] if parent_key.start_with?('.')
        flat_vals = ["#{parent_key} = #{val}"]
      end
      flat_vals
    end
  end
end



