# frozen_string_literal: true

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: [:spec]

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)
