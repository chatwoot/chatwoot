require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "test/lib"
  t.libs << "lib"
  t.ruby_opts << "-rhelper"
  t.test_files = FileList["test/irb/test_*.rb"]
end

# To make sure they have been correctly setup for Ruby CI.
desc "Run each irb test file in isolation."
task :test_in_isolation do
  failed = false

  FileList["test/irb/test_*.rb"].each do |test_file|
    ENV["TEST"] = test_file
    begin
      Rake::Task["test"].execute
    rescue => e
      failed = true
      msg = "Test '#{test_file}' failed when being executed in isolation. Please make sure 'rake test TEST=#{test_file}' passes."
      separation_line = '=' * msg.length

      puts <<~MSG
        #{separation_line}
        #{msg}
        #{separation_line}
      MSG
    end
  end

  fail "Some tests failed when being executed in isolation" if failed
end

Rake::TestTask.new(:test_yamatanooroti) do |t|
  t.libs << 'test' << "test/lib"
  t.libs << 'lib'
  #t.loader = :direct
  t.ruby_opts << "-rhelper"
  t.pattern = 'test/irb/yamatanooroti/test_*.rb'
end

task :sync_tool do
  require 'fileutils'
  FileUtils.cp "../ruby/tool/lib/core_assertions.rb", "./test/lib"
  FileUtils.cp "../ruby/tool/lib/envutil.rb", "./test/lib"
  FileUtils.cp "../ruby/tool/lib/find_executable.rb", "./test/lib"
end

task :default => :test
