require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'

desc "Run RSpec"
RSpec::Core::RakeTask.new do |t|
  t.verbose = false
end
task :default => :spec
