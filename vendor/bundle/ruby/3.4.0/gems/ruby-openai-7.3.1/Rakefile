require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default do
  Rake::Task["test"].invoke
  Rake::Task["lint"].invoke
end

task :test do
  Rake::Task["spec"].invoke
end

task :lint do
  RuboCop::RakeTask.new(:rubocop)
  Rake::Task["rubocop"].invoke
end
