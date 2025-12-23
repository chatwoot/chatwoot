require 'rubygems'

begin
  require 'bundler/setup'
rescue LoadError => e
  abort e.message
end

require 'rake'
require 'rubygems/tasks'
Gem::Tasks.new

namespace :build do
  desc "Builds the C extensions"
  task :c_exts do
    Dir.chdir('ext/digest') { sh 'rake' }
  end
end

require 'rake/clean'
CLEAN.include('ext/digest/crc*/extconf.h')
CLEAN.include('ext/digest/crc*/Makefile')
CLEAN.include('ext/digest/crc*/*.o')
CLEAN.include('ext/digest/crc*/*.so')

file 'spec/integration/docker/digest-crc.gem' do |t|
  sh "gem build -o #{t.name} digest-crc.gemspec"
end

require 'rspec/core/rake_task'
namespace :spec do
  RSpec::Core::RakeTask.new(:pure) do |t|
    t.exclude_pattern = 'spec/integration/*_spec.rb'
  end
  task :pure => :clean

  if RUBY_ENGINE == 'ruby'
    RSpec::Core::RakeTask.new(:c_exts) do |t|
      t.exclude_pattern = 'spec/integration/*_spec.rb'
    end
    task :c_exts => 'build:c_exts'
  end

  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/*_spec.rb'
  end
end

task :spec => 'spec:pure'
task :spec => 'spec:c_exts' if RUBY_ENGINE == 'ruby'

task :test => :spec
task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
task :doc => :yard
