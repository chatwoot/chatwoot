# frozen_string_literal: true

require "bundler"
require "bundler/setup"
Bundler::GemHelper.install_tasks

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
  t.warning = false
end

require "rubocop/rake_task"
desc "Run rubocop"
task :rubocop do
  RuboCop::RakeTask.new do |t|
    t.options += %w[
      --display-style-guide
      --display-cop-names
      --extra-details
      --auto-correct
    ]
  end
end

desc "Run specs against all gemfiles"
task "test:all" do
  %w[
    Gemfile
    gemfiles/rails4.gemfile
  ].each do |gemfile|
    puts "=> Running with Gemfile: #{gemfile}"
    system "BUNDLE_GEMFILE=#{gemfile} rake test"
  end
end

task default: %i[test rubocop]
