# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require 'bundler/gem_tasks'
require 'rake/testtask'
require "rubocop/rake_task"

RuboCop::RakeTask.new

namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.pattern = "spec/*_spec.rb"
  end

  Rake::TestTask.new(:integration) do |t|
    t.pattern = "spec/integration/*_spec.rb"
  end

  Rake::TestTask.new(:acceptance) do |t|
    t.pattern = "spec/acceptance/**/*_spec.rb"
  end
end

Rake::TestTask.new(:test) do |t|
  t.pattern = "spec/**/*_spec.rb"
end

task default: [:rubocop, :test]
