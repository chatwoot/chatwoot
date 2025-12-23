require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Open an irb session preloaded with working_hours"
task :console do
  sh "irb -rubygems -I lib -r working_hours.rb"
end