# frozen_string_literal: true

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rdoc/task'
require 'rspec'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new('spec:progress') do |spec|
  spec.rspec_opts = %w[--format progress]
  spec.pattern = 'spec/**/*_spec.rb'
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "uniform_notifier #{UniformNotifier::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task default: :spec
