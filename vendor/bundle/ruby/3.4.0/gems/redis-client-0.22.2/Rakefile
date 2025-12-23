# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"
require 'rubocop/rake_task'

RuboCop::RakeTask.new

require "rake/clean"
CLOBBER.include "pkg"
require "bundler/gem_helper"
Bundler::GemHelper.install_tasks(name: "redis-client")
Bundler::GemHelper.install_tasks(dir: "hiredis-client", name: "hiredis-client")

gemspec = Gem::Specification.load("redis-client.gemspec")
Rake::ExtensionTask.new do |ext|
  ext.name = "hiredis_connection"
  ext.ext_dir = "hiredis-client/ext/redis_client/hiredis"
  ext.lib_dir = "hiredis-client/lib/redis_client"
  ext.gem_spec = gemspec
  CLEAN.add("#{ext.ext_dir}/vendor/*.{a,o}")
end

namespace :test do
  Rake::TestTask.new(:ruby) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList["test/**/*_test.rb"].exclude("test/sentinel/*_test.rb")
    t.options = '-v' if ENV['CI'] || ENV['VERBOSE']
  end

  Rake::TestTask.new(:sentinel) do |t|
    t.libs << "test/sentinel"
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList["test/sentinel/*_test.rb"]
    t.options = '-v' if ENV['CI'] || ENV['VERBOSE']
  end

  Rake::TestTask.new(:hiredis) do |t|
    t.libs << "test/hiredis"
    t.libs << "test"
    t.libs << "hiredis-client/lib"
    t.libs << "lib"
    t.test_files = FileList["test/**/*_test.rb"].exclude("test/sentinel/*_test.rb")
    t.options = '-v' if ENV['CI'] || ENV['VERBOSE']
  end
end

hiredis_supported = RUBY_ENGINE == "ruby" && !RUBY_PLATFORM.match?(/mswin/)
if hiredis_supported
  task test: %i[test:ruby test:hiredis test:sentinel]
else
  task test: %i[test:ruby test:sentinel]
end

namespace :hiredis do
  task :download do
    version = "1.0.2"
    archive_path = "tmp/hiredis-#{version}.tar.gz"
    url = "https://github.com/redis/hiredis/archive/refs/tags/v#{version}.tar.gz"
    system("curl", "-L", url, out: archive_path) or raise "Downloading of #{url} failed"
    system("rm", "-rf", "hiredis-client/ext/redis_client/hiredis/vendor/")
    system("mkdir", "-p", "hiredis-client/ext/redis_client/hiredis/vendor/")
    system(
      "tar", "xvzf", archive_path,
      "-C", "hiredis-client/ext/redis_client/hiredis/vendor",
      "--strip-components", "1",
    )
    system("rm", "-rf", "hiredis-client/ext/redis_client/hiredis/vendor/examples")
  end
end

benchmark_suites = %w(single pipelined drivers)
benchmark_modes = %i[ruby yjit hiredis]
namespace :benchmark do
  benchmark_suites.each do |suite|
    benchmark_modes.each do |mode|
      next if suite == "drivers" && mode == :hiredis

      name = "#{suite}_#{mode}"
      desc name
      task name do
        output_path = "benchmark/#{name}.md"
        sh "rm", "-f", output_path
        File.open(output_path, "w+") do |output|
          output.puts("ruby: `#{RUBY_DESCRIPTION}`\n\n")
          output.puts("redis-server: `#{`redis-server -v`.strip}`\n\n")
          output.puts
          output.flush
          env = {}
          args = []
          args << "--yjit" if mode == :yjit
          env["DRIVER"] = mode == :hiredis ? "hiredis" : "ruby"
          system(env, RbConfig.ruby, *args, "benchmark/#{suite}.rb", out: output)
        end

        skipping = false
        output = File.readlines(output_path).reject do |line|
          if skipping
            if line == "Comparison:\n"
              skipping = false
              true
            else
              skipping
            end
          else
            skipping = true if line.start_with?("Warming up ---")
            skipping
          end
        end
        File.write(output_path, output.join)
      end
    end
  end

  task all: benchmark_suites.flat_map { |s| benchmark_modes.flat_map { |m| "#{s}_#{m}" } }
end

if hiredis_supported
  task default: %i[compile test rubocop]
  task ci: %i[compile test:ruby test:hiredis]
else
  task default: %i[test rubocop]
  task ci: %i[test:ruby]
end
