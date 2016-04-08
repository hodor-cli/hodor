
$:.push File.expand_path("../lib", __FILE__)
require "hodor/version"

task :default => :run_specs

##################
# Build & Release Tasks
#

require 'bundler/gem_tasks'

##################
# RuboCop Tasks
#
namespace :cop do

  task :depends do
    require 'rubocop/rake_task'
  end

  desc "Run rubocop on Hadoop checks"
  task :cli => :depends do
    cli = RuboCop::RakeTask.new do |task|
      task.formatters = ["s"]
      task.patterns = ["lib/", "spec/"]
    end
    Rake::Task["rubocop"].invoke
  end

  task :all => [:cli]
end

desc "Run lint on all sections"
task :cop => 'cop:all'

##################
# Ruby-Lint Tasks
#
namespace :lint do

  task :depends do
    require 'ruby-lint/rake_task'
  end

  desc "Run lint on cli checks"
  task :cli => :depends do
    RubyLint::RakeTask.new do |task|
      task.name  = 'lint'
      task.files = ['lib/']
    end
    Rake::Task["lint"].invoke
  end

  task :all => [:cli]
end

desc "Run lint on all sections"
task :lint => 'lint:all'

##################
# Rspec Tasks
#
namespace :spec do

  desc "Ensure dependencies load once"
  task :depends do
    require 'rspec/core/rake_task'
  end

  desc "Run unit tests"
  task :unit => :depends do
    RSpec::Core::RakeTask.new("spec:unit")  do |t|
      t.pattern = 'spec/unit/**/*_spec.rb'
      t.fail_on_error = false
      t.rspec_opts = %w(--color --require spec_helper --format progress)
    end
  end

  desc "Run integration tests"
  task :integration => :depends do
    RSpec::Core::RakeTask.new("spec:integration")  do |t|
      t.pattern = 'spec/integration/**/*_spec.rb'
      t.fail_on_error = false
      t.rspec_opts = %w(--color --require spec_helper --format progress)
    end
  end

  desc "Run all specs"
  task :all => ['spec:unit', 'spec:integration']
end

desc "Run spec on all test folders"
task :spec => 'spec:all'
task :specs => 'spec:all'
task :run_specs => 'spec:all'
