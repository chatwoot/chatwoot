require 'rubygems'
require 'bundler/setup'

import "./lib/tasks/tags_collate_utf8.rake"

desc 'Default: run specs'
task default: :spec

desc 'Copy sample spec database.yml over if not exists'
task :copy_db_config do
  cp 'spec/internal/config/database.yml.sample', 'spec/internal/config/database.yml'
end

task spec: [:copy_db_config]

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

Bundler::GemHelper.install_tasks
