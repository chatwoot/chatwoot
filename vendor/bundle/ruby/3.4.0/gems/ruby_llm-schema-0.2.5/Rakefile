# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

# Load custom tasks
Dir.glob("lib/tasks/**/*.rake").each { |r| load r }

RSpec::Core::RakeTask.new(:spec)

task default: %i[standard spec]
