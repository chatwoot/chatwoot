# typed: false
# frozen_string_literal: true

require "rake/testtask"
require "bundler/gem_tasks"

namespace :test do
  Rake::TestTask.new(:library) do |t|
    t.test_files = FileList["test/**/*_test.rb"].exclude("test/rest/**/*.rb")
  end

  Rake::TestTask.new(:rest_wrappers) do |t|
    pattern = if ENV.key?("API_VERSION")
      "test/rest/**/#{ENV.fetch("API_VERSION")}/*.rb"
    else
      "test/rest/**/*.rb"
    end

    t.pattern = pattern
  end
end

task test: ["test:library"]
