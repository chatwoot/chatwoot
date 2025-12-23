# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'rubygems'
require 'rake/testtask'
require 'yard'
require "#{File.dirname(__FILE__)}/lib/tasks/all.rb"
require_relative 'lib/tasks/helpers/prompt'
include Prompt

YARD::Rake::YardocTask.new

task :default => :test
task :test => ['test:newrelic']

namespace :test do
  desc 'Run all tests'
  task :all => %w[newrelic multiverse all_compatible_envs]
  agent_home = File.expand_path(File.dirname(__FILE__))

  desc 'Run agent performance tests'
  task :performance, [:suite, :name] => [] do |t, args|
    require File.expand_path(File.join(File.dirname(__FILE__), 'test', 'performance', 'lib', 'performance'))
    options = {}
    options[:suite] = args[:suite] if args[:suite]
    options[:name] = args[:name] if args[:name]
    Performance::Runner.new(options).run_and_report
  end

  desc 'Run agent within existing mini environment(s): env[name1,name2,name3,etc.]'
  task :env do |t, args|
    require File.expand_path(File.join(File.dirname(__FILE__), 'test', 'environments', 'lib', 'environments', 'runner'))
    Environments::Runner.new(args.to_a).run_and_report
  end

  desc 'Run all mini environment tests known to work with the current Ruby version'
  task :all_compatible_envs do |t, args|
    require File.expand_path(File.join(File.dirname(__FILE__), 'test', 'helpers', 'ruby_rails_mappings'))
    rails_versions = rails_versions_for_ruby_version(RUBY_VERSION)
    Rake::Task['test:env'].invoke(*rails_versions)
  end

  Rake::TestTask.new(:intentional_fail) do |t|
    t.libs << "#{agent_home}/test"
    t.libs << "#{agent_home}/lib"
    t.pattern = "#{agent_home}/test/intentional_fail.rb"
    t.verbose = true
  end

  Rake::TestTask.new(:nullverse) do |t|
    t.pattern = "#{agent_home}/test/nullverse/*_test.rb"
    t.verbose = true
  end

  # Note unit testing task is defined in lib/tasks/tests.rake to facilitate
  # running them in a rails application environment.
end

desc 'Record build number and stage'
task :record_build, [:build_number, :stage] do |t, args|
  build_string = args.build_number
  build_string << ".#{args.stage}" unless args.stage.nil? || args.stage.empty?

  gitsha = File.exist?('.git') ? `git rev-parse HEAD` : 'Unknown'
  gitsha.chomp!

  File.open('lib/new_relic/build.rb', 'w') do |f|
    f.write("# GITSHA: #{gitsha}\n")
    f.write("module NewRelic; module VERSION; BUILD='#{build_string}'; end; end\n")
  end
end

desc 'Update CA bundle'
task :update_ca_bundle do |t|
  ca_bundle_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'SSL_CA_cert_bundle'))
  if !File.exist?(ca_bundle_path)
    puts "Could not find SSL_CA_cert_bundle project at #{ca_bundle_path}. Please clone it."
    exit
  end
  if !File.exist?(File.join(ca_bundle_path, '.git'))
    puts "#{ca_bundle_path} does not appear to be a git repository."
    exit
  end

  puts "Updating bundle at #{ca_bundle_path} with git..."
  result = system("cd #{ca_bundle_path} && git fetch origin && git reset --hard origin/master")
  if result != true
    puts "Failed to update git repo at #{ca_bundle_path}."
    exit
  end

  bundle_last_update = `cd #{ca_bundle_path} && git show -s --format=%ci HEAD`
  puts "Source CA bundle last updated #{bundle_last_update}"

  bundle_path = 'cert/cacert.pem'
  cert_paths = []
  Dir.glob("#{ca_bundle_path}/*.pem").each { |p| cert_paths << p }
  cert_paths.sort!

  puts "Writing #{cert_paths.size} certs to bundle at #{bundle_path}..."

  File.open(bundle_path, 'w') do |f|
    cert_paths.each do |cert_path|
      cert_name = File.basename(cert_path, '.pem')
      puts "Adding #{cert_name}"
      f.write("#{cert_name}\n")
      f.write(File.read(cert_path))
      f.write("\n\n")
    end
  end
  puts "Done, please commit your changes to #{bundle_path}"
end

namespace :cross_agent_tests do
  CROSS_AGENT_TESTS_UPSTREAM_PATH = File.expand_path(File.join('..', 'cross_agent_tests')).freeze
  CROSS_AGENT_TESTS_LOCAL_PATH = File.expand_path(File.join('test', 'fixtures', 'cross_agent_tests')).freeze

  desc 'Pull latest changes from cross_agent_tests repo'
  task :pull do
    command = "  rsync -av --exclude .git #{CROSS_AGENT_TESTS_UPSTREAM_PATH}/ #{CROSS_AGENT_TESTS_LOCAL_PATH}/"
    prompt_to_continue(command)
  end

  desc 'Copy changes from embedded cross_agent_tests to official repo working copy'
  task :push do
    command = "rsync -av #{CROSS_AGENT_TESTS_LOCAL_PATH}/ #{CROSS_AGENT_TESTS_UPSTREAM_PATH}/"
    prompt_to_continue(command, 'remote (agent spec repo)')
  end
end

desc 'Start an interactive console session'
task :console do
  require 'pry' if ENV['ENABLE_PRY']
  require 'newrelic_rpm'
  ARGV.clear
  Pry.start
end
