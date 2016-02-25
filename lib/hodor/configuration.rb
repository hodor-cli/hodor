require 'yaml'
require 'erb'

module Hodor
  class Configuration

    def env
      Environment.instance
    end

    def target
      env.settings[:target]
    end

    def logger
      env.logger
    end

    def initialize(yml_file)
      @yml_file = yml_file
      @kvp = {}
    end

    def load

      @loaded = true

      yml_expand(@target_cluster, [@clusters])
    end

    def yml_expand(val, parents)
      if val.is_a? String
        val.gsub(/\$\{.+?\}/) { |match|
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
        }
      elsif val.is_a? Hash
        more_parents = parents << val
        val.each_pair { |k, v|
          exp_val = yml_expand(v, more_parents)
          val[k] = exp_val
        }
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

    def render_flattened
      flat_vals = yml_flatten('', egress_to)
      flat_vals.join("\n")
    end

  end
end

