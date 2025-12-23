task :release do
  cur = `git branch --show-current`.chomp
  if cur != 'master'
    puts 'Release only from master branch'
    exit(-1)
  end
end

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test/lib"
  t.ruby_opts << "-rhelper"
  t.test_files = FileList["test/**/test_*.rb"]
end

task :default => [:test]
