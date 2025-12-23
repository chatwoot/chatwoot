require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "Run tests"
task :default => :spec

task :console do
  require 'rb-inotify'
  require 'pry'
  
  binding.pry
end
