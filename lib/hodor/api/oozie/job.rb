require 'fileutils'
require 'awesome_print'
require 'stringio'
require 'ox'

require_relative 'session'

module Hodor::Oozie

  class Job 
    attr_reader :index, :id, :parent_id, :skip_to, :conf, :rest_call
    attr_accessor :columns

    def session
      Hodor::Oozie::Session.instance
    end

    def oozie
      Hodor::Oozie
    end

    def initialize
      @index = -1
      @rest_call = session.last_query
    end

    def set_index(i)
      @index = i
    end

    def indexed_job_id
      nil
    end

    def parse_time timestamp
      Time.strptime(timestamp, "%a, %d %b %Y %H:%M:%S %Z") if timestamp
    end

    def expand
      nil
    end

    def children
      if @children.nil?
        @children = expand
      end
      @children
    end

    def display_as_time(val)
      display_date = val.strftime("%Y-%m-%d %H:%M %Z")
      cur_date = Time.now.strftime("%Y-")
      if display_date[0..4].eql?(cur_date)
        display_date[5..-1]
      else
        display_date
      end
    end

    def sanitize val, max_length = 120
      sval = val.to_s.gsub(/\s+/, ' ')
      if sval.length > max_length
        sval.to_s[0..max_length-3] + '...'
      else
        sval
      end
    end

    def title
      "#{session.hadoop_env.capitalize}: #{self.class.name.split('::').last} Properties"
    end

    def display_properties
      if self.class.respond_to?(:suppress_properties)
        suppress = self.class.suppress_properties
      else
        suppress = false
      end
      props = suppress ? nil :
        instance_variables.map { |var| var[1..-1] }.select { |var| !var.eql?("index") }
      if props
        rows = props.inject([]) { |result, prop|
          display_override = "display_#{prop.to_s}".to_sym
          if respond_to?(display_override)
            val = method(display_override.to_s).call
          else
            val = instance_variable_get("@#{prop}")
            if val.is_a?(Time)
              val = display_as_time(val)
            else
              val = val
            end
          end
          result << [prop, sanitize(val)]
        }

        utc_time = display_as_time(Time.now.utc)
        local_time = Time.now.strftime("%H:%M %Z")
        rows << [ "Target", "#{session.hadoop_env.capitalize} @ #{utc_time} / #{local_time}" ]
        { rows: rows }
      else
        nil
      end
    end

    def display_as_array(columns, ellipsis = false)
      row = columns.inject([]) { |cols, head|
        if ellipsis
          val = "..."
        else
          display_override = "display_#{head.to_s}".to_sym
          if respond_to?(display_override)
            val = method(display_override.to_s).call
          else
            val = instance_variable_get("@#{head}")
            val = display_as_time(val) if val.is_a?(Time)
          end
        end
        cols << sanitize(val, 80)
      }
    end

    def child_columns
      first_child = children.first
      if first_child
        first_child.class.default_columns
      else
        nil
      end
    end

    def children_title
      "#{self.class.name.split('::').last} Children"
    end

    def display_children
      if children.nil? || children.length == 0
        nil
      else
        headings = child_columns.map { |head| 
          head.to_s.split('_').map { |w| w.capitalize }.join(' ')
        }
        children.each_with_index { |c, i|
          c.set_index(i)
        }

        truncated = children.length > session.len
        childrows = truncated ? children[0..session.len-1] : children

        rows = childrows.inject([]) { |result, v|
          result << v.display_as_array(child_columns)
          result
        }

        rows[rows.length-1][0] = "#{rows[rows.length-1][0]}+" if truncated
        { headings: headings, rows: rows }
      end
    end

    class Configuration < ::Ox::Sax
      attr_reader :map

      def initialize 
        @map = {}
      end

      def start_element(key)
        @incoming = key
      end

      def text(incoming)
        case @incoming
        when :name;
          @key = incoming
        when :value;
          @map[@key] = incoming
        end
      end
    end

    def conf_map
      io = StringIO.new(conf || "")
      handler = Configuration.new()
      Ox.sax_parse(handler, io)
      handler.map
    end

    def log
      session.get_job_state(id, "show=log")
    end

    def definition
      session.get_job_state(id, "show=definition")
    end
  end
end
