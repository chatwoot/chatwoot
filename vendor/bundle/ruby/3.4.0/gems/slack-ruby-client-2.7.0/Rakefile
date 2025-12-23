# frozen_string_literal: true
require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'

Bundler.setup :default, :development

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task default: %i[spec rubocop]

load 'tasks/git.rake'
load 'tasks/web.rake'
load 'tasks/real_time.rake'
load 'tasks/update.rake'
