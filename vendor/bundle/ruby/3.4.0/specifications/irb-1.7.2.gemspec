# -*- encoding: utf-8 -*-
# stub: irb 1.7.2 ruby lib

Gem::Specification.new do |s|
  s.name = "irb".freeze
  s.version = "1.7.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/ruby/irb/releases", "documentation_uri" => "https://github.com/ruby/irb", "homepage_uri" => "https://github.com/ruby/irb", "source_code_uri" => "https://github.com/ruby/irb" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["aycabta".freeze, "Keiju ISHITSUKA".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-07-11"
  s.description = "Interactive Ruby command-line tool for REPL (Read Eval Print Loop).".freeze
  s.email = ["aycabta@gmail.com".freeze, "keiju@ruby-lang.org".freeze]
  s.executables = ["irb".freeze]
  s.files = ["exe/irb".freeze]
  s.homepage = "https://github.com/ruby/irb".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.5.0.dev".freeze
  s.summary = "Interactive Ruby command-line tool for REPL (Read Eval Print Loop).".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<reline>.freeze, [">= 0.3.6".freeze])
end
