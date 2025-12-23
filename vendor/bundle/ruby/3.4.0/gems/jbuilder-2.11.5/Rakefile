require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["CI"]
  require "appraisal/task"
  Appraisal::Task.new
  task default: :appraisal
else
  Rake::TestTask.new do |test|
    require "rails/version"

    test.libs << "test"

    test.test_files = FileList["test/*_test.rb"]
  end

  task default: :test
end
