# frozen_string_literal: true

require_relative "lib/rake/version"

Gem::Specification.new do |s|
  s.name = "rake"
  s.version = Rake::VERSION
  s.authors = ["Hiroshi SHIBATA", "Eric Hodel", "Jim Weirich"]
  s.email = ["hsbt@ruby-lang.org", "drbrain@segment7.net", ""]

  s.summary = "Rake is a Make-like program implemented in Ruby"
  s.description = <<~DESCRIPTION
    Rake is a Make-like program implemented in Ruby. Tasks and dependencies are
    specified in standard Ruby syntax.
    Rake has the following features:
      * Rakefiles (rake's version of Makefiles) are completely defined in standard Ruby syntax.
        No XML files to edit. No quirky Makefile syntax to worry about (is that a tab or a space?)
      * Users can specify tasks with prerequisites.
      * Rake supports rule patterns to synthesize implicit tasks.
      * Flexible FileLists that act like arrays but know about manipulating file names and paths.
      * Supports parallel execution of tasks.
  DESCRIPTION
  s.homepage = "https://github.com/ruby/rake"
  s.licenses = ["MIT"]

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/ruby/rake/issues",
    "changelog_uri" => "https://github.com/ruby/rake/blob/v#{s.version}/History.rdoc",
    "documentation_uri" => "https://ruby.github.io/rake",
    "source_code_uri" => "https://github.com/ruby/rake/tree/v#{s.version}"
  }

  s.files = [
    "History.rdoc",
    "MIT-LICENSE",
    "README.rdoc",
    "doc/command_line_usage.rdoc",
    "doc/example/Rakefile1",
    "doc/example/Rakefile2",
    "doc/example/a.c",
    "doc/example/b.c",
    "doc/example/main.c",
    "doc/glossary.rdoc",
    "doc/jamis.rb",
    "doc/proto_rake.rdoc",
    "doc/rake.1",
    "doc/rakefile.rdoc",
    "doc/rational.rdoc",
    "exe/rake",
    "lib/rake.rb",
    "lib/rake/application.rb",
    "lib/rake/backtrace.rb",
    "lib/rake/clean.rb",
    "lib/rake/cloneable.rb",
    "lib/rake/cpu_counter.rb",
    "lib/rake/default_loader.rb",
    "lib/rake/dsl_definition.rb",
    "lib/rake/early_time.rb",
    "lib/rake/ext/core.rb",
    "lib/rake/ext/string.rb",
    "lib/rake/file_creation_task.rb",
    "lib/rake/file_list.rb",
    "lib/rake/file_task.rb",
    "lib/rake/file_utils.rb",
    "lib/rake/file_utils_ext.rb",
    "lib/rake/invocation_chain.rb",
    "lib/rake/invocation_exception_mixin.rb",
    "lib/rake/late_time.rb",
    "lib/rake/linked_list.rb",
    "lib/rake/loaders/makefile.rb",
    "lib/rake/multi_task.rb",
    "lib/rake/name_space.rb",
    "lib/rake/packagetask.rb",
    "lib/rake/phony.rb",
    "lib/rake/private_reader.rb",
    "lib/rake/promise.rb",
    "lib/rake/pseudo_status.rb",
    "lib/rake/rake_module.rb",
    "lib/rake/rake_test_loader.rb",
    "lib/rake/rule_recursion_overflow_error.rb",
    "lib/rake/scope.rb",
    "lib/rake/task.rb",
    "lib/rake/task_argument_error.rb",
    "lib/rake/task_arguments.rb",
    "lib/rake/task_manager.rb",
    "lib/rake/tasklib.rb",
    "lib/rake/testtask.rb",
    "lib/rake/thread_history_display.rb",
    "lib/rake/thread_pool.rb",
    "lib/rake/trace_output.rb",
    "lib/rake/version.rb",
    "lib/rake/win32.rb",
    "rake.gemspec"
  ]
  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = Gem::Requirement.new(">= 2.3")
  s.rdoc_options = ["--main", "README.rdoc"]
end
