require 'net/http'
require 'uri'
require 'json'
require 'singleton'

module Hodor::Oozie
  class Session
    include Singleton

    attr_accessor :mode, :verbose, :filter, :len, :offset
    attr_reader :last_query

    def env
      Hodor::Environment.instance
    end

    def logger
      env.logger
    end

    def hadoop_env
      env.hadoop_env
    end

    def initialize
      @len = env.prefs[:default_list_length] || 30
      @offset = 0
    end

    def rest_call(api)
      num_retries = 0
      begin
        url = "#{env[:oozie_url]}#{api}".gsub(/oozie\/\//,'oozie/')
        @last_query = url
        #puts "REST CALL: #{url}"
        uri = URI.parse(url)

        http = Net::HTTP.new(uri.host, uri.port)

        http.read_timeout = 10
        http.open_timeout = 10

        data = http.start() {|http|
          http.get(uri.request_uri).body
        }
      rescue Net::OpenTimeout => ex
        logger.error "Network connection timed out! Make sure you are connected to the Internet or VPN. Retrying..."
        if num_retries <= 4
          num_retries += 1
          retry
        else
          nil
        end
      end
    end

    def search_jobs(*args)
      json = rest_call("/v2/jobs?#{args.map { |v| v.nil? || v.size == 0 ? nil : v }.compact.join('&')}")
      @root_query = @last_query
      json
    end

    def get_job_state(job_id, *args)
      rest_call("/v1/job/#{job_id}?#{args.map { |v| v.nil? || v.size == 0 ? nil : v }.compact.join('&')}")
    end

    def refresh_index(children, current_id, parent_id)
      if children
        children.each_with_index { |c, i|
          c.set_index(i)
        }
        child_ids = children.map { |c| c.skip_to || c.id }
      else
        child_ids = nil
      end
      index_overwrite = { children: child_ids,
                current_id: current_id,
                parent_id: parent_id,
                root_query: @root_query }
      File.open(cache_file, 'wb') {|f| f.write(::Marshal.dump(index_overwrite)) }
      children
    end

    def index
      if @index.nil?
        @index = load_index
      end
      @index
    end

    def child_id(child_index)
      children = index[:children]
      if children
        index_size = index[:children].length
        if child_index < index_size
          cid = index[:children][child_index]
          cid
        else
          raise "No child with index '#{child_index}' was found"
        end
      end
    end

    def current_id
      index[:current_id]
    end

    def parent_id
      index[:parent_id]
    end

    def root_query
      @root_query || index[:root_query]
    end

    def cache_file
      if @cache_file.nil?
        if env[:display_job_query_mode]
          default_id = 'default'
        else
          default_id = `ps -p #{Process.pid} -o ppid=`.strip
        end
        index_id = ENV['HODOR_INDEX_ID'] || default_id
        @cache_file = "/tmp/hodor-#{index_id}.index"
      end
      @cache_file
    end

    def load_index
      index_read = {}
      if File.exists? cache_file
        File.open(cache_file, 'rb') {|f| index_read = ::Marshal.load(f) } 
        @root_query ||= index_read[:root_query] if index_read.has_key?(:root_query)
      else
        index_read = { children: nil,
                current_id: nil,
                parent_id: nil,
                root_query: nil }
      end
      index_read || { children: nil,
                      current_id: nil,
                      parent_id: nil,
                      root_query: nil }
    rescue => ex
      raise "Failed to load Hodor cache file. #{ex.message}"
    end

    def pwj
      { current_id: session.current_id,
        parent_id: session.parent_id,
        root_query: session.root_query }
    end

    def job_relative(movement, request = nil)
      case movement
      when :root;
        nil
      when :up; 
        parent_id
      when :down; 
        child_id(request.to_i)
      when :none; 
        current_id
      when :jump;
        request
      end
    end

    def make_current(job)
      refresh_index(job.children, job.id, job.parent_id) if job
      job
    end
  end
end
