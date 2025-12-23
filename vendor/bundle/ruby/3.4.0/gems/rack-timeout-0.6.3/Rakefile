require 'rake/testtask'
require 'bundler/gem_tasks'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task :fix_permissions do
  FileUtils.chmod_R("a+rX", File.dirname(__FILE__))
end

task(:build).enhance([:fix_permissions])

task :default => :test
