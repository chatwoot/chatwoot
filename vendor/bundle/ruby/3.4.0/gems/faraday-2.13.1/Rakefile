# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'bundler'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |task|
  task.ruby_opts = %w[-W]
end

task default: :spec
