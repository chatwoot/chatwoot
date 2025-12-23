def name
  @name ||= Dir["*.gemspec"].first.split(".").first
end

def version
  @version ||= File.read("lib/#{name}.rb")[/^\s*VERSION\s*=\s*['"](?'version'\d+\.\d+\.\d+)['"]/, "version"]
end

task default: :test

require "rake/testtask"
Rake::TestTask.new(:test)
