require "hodor/version"

module Hodor

  # Hodor Exception Classes
  class NestedError < StandardError
    attr_reader :cause

    def initialize(cause, kvp = {})
      @cause = cause
      @kvp = kvp
    end

    alias :orig_to_s :to_s
    def to_s
      msg = @kvp[:msg] || orig_to_s
      if @kvp.size > 1 || (@kvp.size == 1 && !@kvp.has_key?(:msg))
        msg << " Exception Context:\n"
        @kvp.each_pair { |k,v|
          next if k == :msg
          if k.nil?
            msg << "   nil => "
          elsif k.is_a?(Symbol)
            msg << "   :#{k.to_s} => "
          else
            msg <<  "   #{k} => "
          end
          if v.nil?
            msg << "nil"
          elsif v.is_a?(Symbol)
            msg << ":#{v.to_s}"
          else
            msg << v
          end
          msg << "\n"
        }
      end
      msg << "Root cause: #{@cause}"
      msg << "\nBacktrace:\n         "
      msg << "#{@cause.backtrace[0..5].join("\n         ")}"
    end
  end

  class AbnormalExitStatus  < StandardError
    attr_reader :exit_status
    def initialize(exit_status, error_lines)
      @exit_status = exit_status
      super error_lines
    end
  end

  class << self
    def using(target = nil)
      Environment.instance.reset(target)
      Environment.instance.settings
    end

    def [](key)
      Environment.instance.settings[key]
    end

    def target
      Environment.instance.hadoop_env
    end

    def run(cmdline)
      require_relative 'hodor/cli'
      $thor_runner = true
      $hodor_runner = true
      Hodor::Cli::Runner.start(cmdline.squish.split)
    rescue Hodor::Cli::CommandNotFound => ex
      puts "Error! Command not found."
    end
  end

end

class Hash
  def normalize_keys
    inject({}) { |memo,(k,v)| 
      memo[k.to_s] = v.is_a?(Hash) ? v.normalize_keys : v;
      memo[k.to_sym] = v.is_a?(Hash) ? v.normalize_keys : v;
      memo
    }
  end

  def recursive_merge(new_hash)
    self.merge(new_hash) do |key, old, new|
      if new.respond_to?(:blank) && new.blank?
        old
      elsif (old.kind_of?(Hash) and new.kind_of?(Hash))
        old.recursive_merge(new)
      else
        new
      end
    end
  end

  def recursive_merge!(new_hash)
    self.merge!(new_hash) do |key, old, new|
      if new.respond_to?(:blank) && new.blank?
        old
      elsif (old.kind_of?(Hash) and new.kind_of?(Hash))
        old.recursive_merge!(new)
      else
        new
      end
    end
  end

  def self.deep_merge(source_hash, new_hash)
  source_hash.merge(new_hash) do |key, old, new|
    if new.respond_to?(:blank) && new.blank?
      old
    elsif (old.kind_of?(Hash) and new.kind_of?(Hash))
      deep_merge(old, new)
    else
      new
    end
  end
  end

  def match strings
    select { |key,val|
      is_match = false
      strings.each { |findstr|
        is_match ||= key.downcase.include?(findstr) || val.downcase.include?(findstr)
      }
      is_match
    }
  end
end

class String
  def unindent(count)
    gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
  end

  def squish
    gsub("\n", ' ').squeeze(' ')
  end
end

require "hodor/environment"
require "hodor/api/oozie"
require "hodor/api/hdfs"
