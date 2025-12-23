require 'bundler/gem_tasks'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/unit/**/*_test.rb', 'test/integration/**/*_test.rb']
  t.warning = false
  t.verbose = false
end

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.test_files = FileList['test/unit/**/*_test.rb']
    t.warning = false
    t.verbose = false
  end

  Rake::TestTask.new(:integration) do |t|
    t.test_files = FileList['test/integration/**/*_test.rb']
    t.warning = false
    t.verbose = false
  end
end
