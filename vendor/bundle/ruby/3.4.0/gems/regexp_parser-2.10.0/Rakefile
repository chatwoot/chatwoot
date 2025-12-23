require 'bundler'
require 'rubygems'
require 'rubygems/package_task'
require 'rake'
require 'rake/testtask'
require 'rspec/core/rake_task'

Dir['tasks/**/*.rake'].each { |file| load(file) }

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec)

task :default => [:'test:full']

namespace :test do
  task full: [:'ragel:rb', :spec]
end

# Add ragel task as a prerequisite for building the gem to ensure that the
# latest scanner code is generated and included in the build.
desc "Runs ragel:rb before building the gem"
task :build => ['ragel:rb']
