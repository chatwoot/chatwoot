require "bundler/gem_tasks"
require "rake/testtask"

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs << "test"
    t.test_files = FileList["test/unit_test.rb"]
    t.verbose = true
  end

  Rake::TestTask.new(:acceptance) do |t|
    t.libs << "test"
    t.test_files = FileList["test/acceptance_test.rb"]
    t.verbose = true
  end
end

desc 'Run tests'
task test: ['test:unit', 'test:acceptance']

task default: :test
