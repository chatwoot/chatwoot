#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rake/testtask'

desc 'Test the representable gem.'
task :default => :test

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/*_test.rb']
  test.verbose = true
end
