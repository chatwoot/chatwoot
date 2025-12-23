#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rake/testtask"

# "Explicit mode" cannot be truly tested if that process has already `require`d attr_extras.
# Thus, we need separate test suites.

explicit_tests = [ "spec/attr_extras/explicit_spec.rb" ]

Rake::TestTask.new(:test_implicit) do |t|
  implicit_tests = FileList["spec/**/*_spec.rb"] - explicit_tests

  t.libs << "spec"
  t.test_files = implicit_tests
end

Rake::TestTask.new(:test_explicit) do |t|
  t.libs << "spec"
  t.test_files = explicit_tests
end

task test: [ :test_implicit, :test_explicit ]
task default: :test
