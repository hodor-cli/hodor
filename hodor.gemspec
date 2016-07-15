# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require 'hodor/version'

Gem::Specification.new do |spec|
  spec.name          = "hodor"
  spec.version       = Hodor::VERSION
  spec.authors       = ["Dean Hallman"]
  spec.email         = ["rdhallman@gmail.com"]
  spec.summary       = %q{Manages Hadoop and Oozie data pipelines, through development, testing, deployment and monitoring}
  spec.description   = %q{Hodor is a ruby-based framework, API and Command Line Interface that automates and simplifies the way you specify, deploy, debug and administer Hadoop and Oozie solutions. Hadoop lacks a mature toolchain to manage a codebase with modern software development discipline. To address this need, Hodor comprises a combination of tools and conventions that enable in the Hadoop environment many of the modern software development practices, and deployment facilities we take for granted in normal software development.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.3'

  spec.add_runtime_dependency "thor", ">= 0.19.1"
  spec.add_runtime_dependency "log4r", "~> 1.1"
  spec.add_runtime_dependency "open4"
  spec.add_runtime_dependency "terminal-table"
  spec.add_runtime_dependency "awesome_print"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "byebug"

  # Gems needed by Hodor's Hadoop/Oozie API
  spec.add_runtime_dependency "rest-client"
  spec.add_runtime_dependency "chronic"
  spec.add_runtime_dependency "ox"

  # Gems needed for managing edn configs (Secret handling)

  spec.add_runtime_dependency 'edn'
  spec.add_runtime_dependency 'aws-sdk'
  spec.add_runtime_dependency 'activesupport'

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "wrong"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "ruby-lint"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rspec-nc"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-remote"
  spec.add_development_dependency "pry-nav"
end

