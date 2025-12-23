require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'bundler'
Bundler::GemHelper.install_tasks

desc 'Default: run unit tests.'
task default: :test

desc 'Test the flag_shih_tzu plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the flag_shih_tzu plugin.'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'FlagShihTzu'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

if defined?(Reek) # No Reek on JRuby
  require 'reek/rake/task'
  Reek::Rake::Task.new do |t|
    t.fail_on_error = true
    t.verbose = false
    t.source_files = 'lib/**/*.rb'
  end
end

if defined?(Roodi) # No Roodi on JRuby
  require 'roodi_task'
  RoodiTask.new do |t|
    t.verbose = false
  end
end

namespace :test do
  desc 'Test against all supported ActiveRecord versions'
  task :all do
    sh "bin/test.bash"
  end
end
