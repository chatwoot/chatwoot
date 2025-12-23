# frozen_string_literal: true

require "date"
require "rake/clean"
require "rake/extensiontask"
require "digest/md5"

host_os = RbConfig::CONFIG["host_os"]
require "devkit" if host_os == "mingw32"

task default: [:test]

# Gem Spec
gem_spec = Gem::Specification.load("commonmarker.gemspec")

# Ruby Extension
Rake::ExtensionTask.new("commonmarker", gem_spec) do |ext|
  ext.lib_dir = File.join("lib", "commonmarker")
end

# Packaging
require "bundler/gem_tasks"

# Testing
require "rake/testtask"

Rake::TestTask.new("test:unit") do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/test_*.rb"
  t.verbose = true
  t.warning = false
end

desc "Run unit tests"
task "test:unit" => :compile

desc "Run unit and conformance tests"
task test: ["test:unit"]

require "rubocop/rake_task"

RuboCop::RakeTask.new(:rubocop)

desc "Run benchmarks"
task :benchmark do
  if ENV["FETCH_PROGIT"]
    %x(rm -rf test/progit)
    %x(git clone https://github.com/progit/progit.git test/progit)
    langs = ["ar", "az", "be", "ca", "cs", "de", "en", "eo", "es", "es-ni", "fa", "fi", "fr", "hi", "hu", "id", "it", "ja", "ko", "mk", "nl", "no-nb", "pl", "pt-br", "ro", "ru", "sr", "th", "tr", "uk", "vi", "zh", "zh-tw"]
    langs.each do |lang|
      %x(cat test/progit/#{lang}/*/*.markdown >> test/benchinput.md)
    end
  end
  $LOAD_PATH.unshift("lib")
  load "test/benchmark.rb"
end

desc "Match C style of cmark"
task :format do
  sh "clang-format -style llvm -i ext/commonmarker/*.c ext/commonmarker/*.h"
end

# Documentation
require "rdoc/task"

desc "Generate API documentation"
RDoc::Task.new do |rd|
  rd.rdoc_dir = "docs"
  rd.main     = "README.md"
  rd.rdoc_files.include("README.md", "lib/**/*.rb", "ext/commonmarker/commonmarker.c")

  rd.options << "--markup tomdoc"
  rd.options << "--inline-source"
  rd.options << "--line-numbers"
  rd.options << "--all"
  rd.options << "--fileboxes"
end

desc "Generate the documentation and run a web server"
task serve: [:rdoc] do
  require "webrick"

  puts "Navigate to http://localhost:3000 to see the docs"

  server = WEBrick::HTTPServer.new(Port: 3000)
  server.mount("/", WEBrick::HTTPServlet::FileHandler, "docs")
  trap("INT") { server.stop }
  server.start
end

desc "Generate and publish docs to gh-pages"
task publish: [:rdoc] do
  require "tmpdir"
  require "shellwords"

  Dir.mktmpdir do |tmp|
    system "mv docs/* #{tmp}"
    system "git checkout origin/gh-pages"
    system "rm -rf *"
    system "mv #{tmp}/* ."
    message = Shellwords.escape("Site updated at #{Time.now.utc}")
    system "git add ."
    system "git commit -am #{message}"
    system "git push origin gh-pages --force"
    system "git checkout master"
    system "echo yolo"
  end
end
