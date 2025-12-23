require 'rspec/core/rake_task'
require "bundler/gem_tasks"
require "rake/tasklib"
require 'ci/reporter/rake/rspec'

RSpec::Core::RakeTask.new(:spec => ["ci:setup:rspec"]) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--format documentation']
end

task :default => :spec
