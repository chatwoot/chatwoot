begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task default: [:spec, :features]
