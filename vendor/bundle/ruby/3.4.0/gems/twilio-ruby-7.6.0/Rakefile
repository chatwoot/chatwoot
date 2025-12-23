require 'bundler'
Bundler.setup
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
desc 'Run all specs'
RSpec::Core::RakeTask.new(:spec)

task default: :spec
task test: :spec
