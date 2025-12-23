# -*- ruby -*-

require "bundler/gem_tasks"

require "rake/testtask"

Rake::TestTask.new

require "rake/manifest"

Rake::Manifest::Task.new do |t|
  t.patterns = [
    ".autotest",
    ".gemtest",
    ".travis.yml",
    "Gemfile",
    "History.txt",
    "Manifest.txt",
    "README.rdoc",
    "Rakefile",
    "{test,lib}/**/*"
  ]
end

# vim: syntax=Ruby
