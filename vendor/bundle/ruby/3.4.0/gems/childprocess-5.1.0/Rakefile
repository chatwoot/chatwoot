require 'rubygems'
require 'rake'
require 'tmpdir'

require 'bundler'
Bundler::GemHelper.install_tasks

include Rake::DSL if defined?(::Rake::DSL)

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.ruby_opts  = "-I lib:spec -w"
  spec.pattern    = 'spec/**/*_spec.rb'
end

desc 'Run specs for rcov'
RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.ruby_opts = "-I lib:spec"
  spec.pattern   = 'spec/**/*_spec.rb'
  spec.rcov      = true
  spec.rcov_opts = %w[--exclude spec,ruby-debug,/Library/Ruby,.gem --include lib/childprocess]
end

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end

task :clean do
  rm_rf "pkg"
  rm_rf "childprocess.jar"
end

desc 'Create jar to bundle in selenium-webdriver'
task :jar => [:clean, :build] do
  tmpdir = Dir.mktmpdir("childprocess-jar")
  gem_to_package = Dir['pkg/*.gem'].first
  gem_name = File.basename(gem_to_package, ".gem")
  p :gem_to_package => gem_to_package, :gem_name => gem_name

  sh "gem install -i #{tmpdir} #{gem_to_package} --ignore-dependencies --no-rdoc --no-ri"
  sh "jar cf childprocess.jar -C #{tmpdir}/gems/#{gem_name}/lib ."
  sh "jar tf childprocess.jar"
end

task :env do
  $:.unshift File.expand_path("../lib", __FILE__)
  require 'childprocess'
end

desc 'Calculate size of posix_spawn structs for the current platform'
task :generate => :env do
  require 'childprocess/tools/generator'
  ChildProcess::Tools::Generator.generate
end
