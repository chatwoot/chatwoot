# frozen_string_literal: true

require "rake/clean"
require "bundler/gem_tasks"
require "rspec/core/rake_task"

# Default task for `rake` is to run rspec
task default: [:spec]

# Use default rspec rake task
RSpec::Core::RakeTask.new

# Configure `rake clobber` to delete all generated files
CLOBBER.include("pkg", "doc", "coverage")
