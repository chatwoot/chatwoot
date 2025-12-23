# encoding: utf-8 -*-
require 'rubygems' unless defined? Gem
require File.dirname(__FILE__) + "/lib/datadog/ruby_core_source/version"

Gem::Specification.new do |s|
  s.name = "datadog-ruby_core_source"
  s.version = Datadog::RubyCoreSource::VERSION
  s.authors = ["Mark Moseley", "Gabriel Horner", "JetBrains RubyMine Team", "Datadog, Inc."]
  s.email = "dev@datadoghq.com"
  s.homepage = "https://github.com/DataDog/datadog-ruby_core_source"
  s.summary = %q{Provide Ruby core source files}
  s.description = %q{Provide Ruby core source files for C extensions that need them.}
  s.license = "MIT"
  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = '>= 2.5.0'
  s.extra_rdoc_files = [ "README.md"]
  s.files = `git ls-files`.split("\n")
    .reject { |fn| fn.include?('find_includes.rb') }
    .reject { |fn| fn.include?('Gemfile') }
    .reject { |fn| fn.include?('Rakefile') }
    .reject { |fn| fn.include?('.github/') }
    .reject { |fn| fn.include?('.gitignore') }
  s.add_development_dependency "archive-tar-minitar", ">= 0.5.2"
  s.add_development_dependency 'rake', '>= 0.9.2'
  s.add_development_dependency 'minitar-cli'
end
