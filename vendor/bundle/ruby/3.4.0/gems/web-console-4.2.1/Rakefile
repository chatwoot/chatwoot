# frozen_string_literal: true

begin
  require "bundler/setup"
rescue LoadError
  puts "You must `gem install bundler` and `bundle install` to run rake tasks"
end

require "socket"
require "rake/testtask"
require "tmpdir"
require "securerandom"
require "json"
require "web_console/testing/erb_precompiler"

EXPANDED_CWD = File.expand_path(File.dirname(__FILE__))

Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = false
end

Dir["lib/web_console/tasks/**/*.rake"].each { |task| load task  }

Bundler::GemHelper.install_tasks

task default: :test
