# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'rubocop/rake_task'

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RuboCop::RakeTask.new

task default: %w[spec rubocop]

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = './spec/**/*_spec.rb'
end
