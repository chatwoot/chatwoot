require "rubygems"
require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
require "appraisal"

Rake::TestTask.new do |t|
  t.libs.concat %w(pry-rails spec)
  t.pattern = "spec/*_spec.rb"
end

desc 'Start the Rails server'
task :server => :development_env do
  require 'rails/commands/server'
  Rails::Server.start(
    :server => 'WEBrick',
    :environment => 'development',
    :Host => '0.0.0.0',
    :Port => 3000,
    :config => 'config/config.ru'
  )
end

desc 'Start the Rails console'
task :console => :development_env do
  if (Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR >= 1) ||
      Rails::VERSION::MAJOR >= 6
    require 'rails/command'
    require 'rails/commands/console/console_command'
  else
    require 'rails/commands/console'
  end

  Rails::Console.start(Rails.application)
end

task :development_env do
  ENV['RAILS_ENV'] = 'development'
  require File.expand_path('../spec/config/environment', __FILE__)
  Dir.chdir(Rails.application.root)
end

# Must invoke indirectly, using `rake appraisal`.
task :default => [:test]
