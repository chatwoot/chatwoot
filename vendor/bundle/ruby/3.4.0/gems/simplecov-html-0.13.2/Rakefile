# frozen_string_literal: true

require "bundler"
Bundler::GemHelper.install_tasks

# See https://github.com/simplecov-ruby/simplecov/issues/171
desc "Set permissions on all files so they are compatible with both user-local and system-wide installs"
task :fix_permissions do
  system 'bash -c "find . -type f -exec chmod 644 {} \; && find . -type d -exec chmod 755 {} \;"'
end
# Enforce proper permissions on each build
Rake::Task[:build].prerequisites.unshift :fix_permissions

require "rake/testtask"
Rake::TestTask.new(:test) do |test|
  test.libs << "lib" << "test"
  test.pattern = "test/**/test_*.rb"
  test.verbose = true
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    warn "Rubocop is disabled"
  end
end

task default: [:test, :rubocop]

namespace :assets do
  desc "Compiles all assets"
  task :compile do
    puts "Compiling assets"
    require "sprockets"
    require "sprockets/sass_processor"

    Sprockets.register_processor("text/css") do |input|
      {data: input[:data].gsub(/(?<!-|_)url\(['"]?(.+?)['"]?\)/) { "asset-data-url(\"#{Regexp.last_match(1)}\")" }}
    end

    Sprockets.register_processor "text/css", Sprockets::ScssProcessor

    assets = Sprockets::Environment.new do |env|
      env.append_path "assets/javascripts"
      env.append_path "assets/stylesheets"
      env.append_path "public"
      env.js_compressor = :uglify
      env.css_compressor = :scss
    end
    assets["application.js"].write_to("public/application.js")
    assets["application.css"].write_to("public/application.css")
  end
end
