require 'simplecov'

SimpleCov.start do
  add_filter "spec\/"
  add_group "Hodor", "lib\/hodor"
  minimum_coverage 18
  maximum_coverage_drop 5
  refuse_coverage_drop
end

require 'bundler/setup'
Bundler.setup

require 'pry'
require 'hodor'
require 'wrong/adapters/rspec'
require 'support/d_v_r'
require 'support/hodor_api'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) {
    begin
      Module.const_get("Hodor::Environment")
    rescue NameError
      # Do nothing
    else
      Hodor::Environment.send(:define_method, 'root') { 
        File.join(File.dirname(__FILE__), "test_repo")
      }
      Hodor::Environment.send(:define_method, 'hadoop_env') {
        'rspec'
      }
      Hodor::Environment.send(:define_method, 'logger_id') {
        'RspecLogger'
      }
    end
  }

end

def use_settings(settings)
  Hodor::Environment.instance.reset
  allow(Hodor::Environment.instance).to receive(:yml_load).
    once.with("config/clusters.yml") do |arg|
    { rspec: settings }
  end
end

def use_pwd(subdir, chdir=true)
  new_pwd = File.join(File.dirname(__FILE__), "test_repo", subdir)
  if (chdir)
    Dir.chdir new_pwd
  else
    allow(FileUtils).to receive(:pwd).at_least(:once) {
      new_pwd
    }
  end
end



def show job
  table = ::Hodor::Table.new(job)
  puts table.properties
  puts table.children
end

def require_thor(task)
  require 'hodor/cli'
  load File.expand_path("../../lib/tasks/#{task}.thor", __FILE__)
end

require 'hodor/ui/table'
require "hodor/api/oozie/job"
require "hodor/api/oozie/query"
require "hodor/api/oozie/session"
require "hodor/api/oozie/bundle"
require "hodor/api/oozie/coordinator"
require "hodor/api/oozie/materialization"
require "hodor/api/oozie/workflow"
require "hodor/api/oozie/action"
require "hodor/api/oozie/hadoop_job"
require 'hodor/api/oozie'
