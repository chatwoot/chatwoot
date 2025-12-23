require 'rake/testtask'
require "rake/clean"

CLOBBER.include "pkg"

Bundler::GemHelper.install_tasks name: ENV.fetch('GEM_NAME', 'skiptrace')

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

case RUBY_ENGINE
when 'ruby'
  require 'rake/extensiontask'

  Rake::ExtensionTask.new('skiptrace') do |ext|
    ext.name = 'cruby'
    ext.lib_dir = 'lib/skiptrace/internal'
  end

  task default: [:clean, :compile, :test]
when 'jruby'
  require 'rake/javaextensiontask'

  Rake::JavaExtensionTask.new('skiptrace') do |ext|
    ext.name = 'jruby_internals'
    ext.lib_dir = 'lib/skiptrace/internal'
    ext.source_version = '1.8'
    ext.target_version = '1.8'
  end

  task default: [:clean, :compile, :test]
else
  task default: [:test]
end
