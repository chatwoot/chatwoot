# frozen_string_literal: true

require "rubygems"
require "hoe"
require "rake/clean"

# This is required until https://github.com/seattlerb/hoe/issues/112 is fixed
class Hoe
  def with_config
    config = Hoe::DEFAULT_CONFIG

    rc = File.expand_path("~/.hoerc")
    homeconfig = load_config(rc)
    config = config.merge(homeconfig)

    localconfig = load_config(File.expand_path(File.join(Dir.pwd, ".hoerc")))
    config = config.merge(localconfig)

    yield config, rc
  end

  def load_config(name)
    File.exist?(name) ? safe_load_yaml(name) : {}
  end

  def safe_load_yaml(name)
    return safe_load_yaml_file(name) if YAML.respond_to?(:safe_load_file)

    data = IO.binread(name)
    YAML.safe_load(data, permitted_classes: [Regexp])
  rescue
    YAML.safe_load(data, [Regexp])
  end

  def safe_load_yaml_file(name)
    YAML.safe_load_file(name, permitted_classes: [Regexp])
  rescue
    YAML.safe_load_file(name, [Regexp])
  end
end

Hoe.plugin :doofus
Hoe.plugin :gemspec2
Hoe.plugin :git
Hoe.plugin :minitest
Hoe.plugin :email unless ENV["CI"]

spec = Hoe.spec "mime-types" do
  developer("Austin Ziegler", "halostatue@gmail.com")
  self.need_tar = true

  require_ruby_version ">= 2.0"

  self.history_file = "History.md"
  self.readme_file = "README.rdoc"

  license "MIT"

  extra_deps << ["mime-types-data", "~> 3.2015"]

  extra_dev_deps << ["hoe-doofus", "~> 1.0"]
  extra_dev_deps << ["hoe-gemspec2", "~> 1.1"]
  extra_dev_deps << ["hoe-git", "~> 1.6"]
  extra_dev_deps << ["hoe-rubygems", "~> 1.0"]
  extra_dev_deps << ["standard", "~> 1.0"]
  extra_dev_deps << ["minitest", "~> 5.4"]
  extra_dev_deps << ["minitest-autotest", "~> 1.0"]
  extra_dev_deps << ["minitest-focus", "~> 1.0"]
  extra_dev_deps << ["minitest-bonus-assertions", "~> 3.0"]
  extra_dev_deps << ["minitest-hooks", "~> 1.4"]
  extra_dev_deps << ["rake", ">= 10.0", "< 14.0"]

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.0")
    extra_dev_deps << ["simplecov", "~> 0.7"]
  end
end

namespace :benchmark do
  task :support do
    %w[lib support].each { |path|
      $LOAD_PATH.unshift(File.join(Rake.application.original_dir, path))
    }
  end

  desc "Benchmark Load Times"
  task :load, [:repeats] => "benchmark:support" do |_, args|
    require "benchmarks/load"
    Benchmarks::Load.report(
      File.join(Rake.application.original_dir, "lib"),
      args.repeats
    )
  end

  desc "Allocation counts"
  task :allocations, [:top_x, :mime_types_only] => "benchmark:support" do |_, args|
    require "benchmarks/load_allocations"
    Benchmarks::LoadAllocations.report(
      top_x: args.top_x,
      mime_types_only: args.mime_types_only
    )
  end

  desc "Columnar allocation counts"
  task "allocations:columnar", [:top_x, :mime_types_only] => "benchmark:support" do |_, args|
    require "benchmarks/load_allocations"
    Benchmarks::LoadAllocations.report(
      columnar: true,
      top_x: args.top_x,
      mime_types_only: args.mime_types_only
    )
  end

  desc "Columnar allocation counts (full load)"
  task "allocations:columnar:full", [:top_x, :mime_types_only] => "benchmark:support" do |_, args|
    require "benchmarks/load_allocations"
    Benchmarks::LoadAllocations.report(
      columnar: true,
      top_x: args.top_x,
      mime_types_only: args.mime_types_only,
      full: true
    )
  end

  desc "Memory profiler"
  task :memory, [:top_x, :mime_types_only] => "benchmark:support" do |_, args|
    require "benchmarks/memory_profiler"
    Benchmarks::ProfileMemory.report(
      mime_types_only: args.mime_types_only,
      top_x: args.top_x
    )
  end

  desc "Columnar memory profiler"
  task "memory:columnar", [:top_x, :mime_types_only] => "benchmark:support" do |_, args|
    require "benchmarks/memory_profiler"
    Benchmarks::ProfileMemory.report(
      columnar: true,
      mime_types_only: args.mime_types_only,
      top_x: args.top_x
    )
  end

  desc "Columnar allocation counts (full load)"
  task "memory:columnar:full", [:top_x, :mime_types_only] => "benchmark:support" do |_, args|
    require "benchmarks/memory_profiler"
    Benchmarks::ProfileMemory.report(
      columnar: true,
      full: true,
      top_x: args.top_x,
      mime_types_only: args.mime_types_only
    )
  end

  desc "Object counts"
  task objects: "benchmark:support" do
    require "benchmarks/object_counts"
    Benchmarks::ObjectCounts.report
  end

  desc "Columnar object counts"
  task "objects:columnar" => "benchmark:support" do
    require "benchmarks/object_counts"
    Benchmarks::ObjectCounts.report(columnar: true)
  end

  desc "Columnar object counts (full load)"
  task "objects:columnar:full" => "benchmark:support" do
    require "benchmarks/object_counts"
    Benchmarks::ObjectCounts.report(columnar: true, full: true)
  end
end

namespace :profile do
  directory "tmp/profile"

  CLEAN.add "tmp"

  def ruby_prof(script)
    require "pathname"
    output = Pathname("tmp/profile").join(script)
    output.mkpath
    script = Pathname("support/profile").join("#{script}.rb")

    args = [
      "-W0",
      "-Ilib",
      "-S", "ruby-prof",
      "-R", "mime/types",
      "-s", "self",
      "-p", "multi",
      "-f", output.to_s,
      script.to_s
    ]
    ruby args.join(" ")
  end

  task full: "tmp/profile" do
    ruby_prof "full"
  end

  task columnar: :support do
    ruby_prof "columnar"
  end

  task "columnar:full" => :support do
    ruby_prof "columnar_full"
  end
end

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.0")
  namespace :test do
    desc "Run test coverage"
    task :coverage do
      spec.test_prelude = [
        'require "simplecov"',
        'SimpleCov.start("test_frameworks") { command_name "Minitest" }',
        'gem "minitest"'
      ].join("; ")
      Rake::Task["test"].execute
    end
  end
end

namespace :convert do
  namespace :docs do
    task :setup do
      gem "rdoc"
      require "rdoc/rdoc"
      @doc_converter ||= RDoc::Markup::ToMarkdown.new
    end

    FileList["*.rdoc"].each do |name|
      rdoc = name
      mark = "#{File.basename(name, ".rdoc")}.md"

      file mark => [rdoc, :setup] do |t|
        puts "#{rdoc} => #{mark}"
        File.open(t.name, "wb") { |target|
          target.write @doc_converter.convert(IO.read(t.prerequisites.first))
        }
      end

      CLEAN.add mark

      task run: [mark]
    end
  end

  desc "Convert documentation from RDoc to Markdown"
  task docs: "convert:docs:run"
end

namespace :deps do
  task :top, [:number] => "benchmark:support" do |_, args|
    require "deps"
    Deps.run(args)
  end
end

task :console do
  arguments = %w[irb]
  arguments.push(*spec.spec.require_paths.map { |dir| "-I#{dir}" })
  arguments.push("-r#{spec.spec.name.gsub("-", File::SEPARATOR)}")
  unless system(*arguments)
    error "Command failed: #{show_command}"
    abort
  end
end

# vim: syntax=ruby
