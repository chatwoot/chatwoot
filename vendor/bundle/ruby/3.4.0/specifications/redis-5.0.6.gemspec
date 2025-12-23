# -*- encoding: utf-8 -*-
# stub: redis 5.0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "redis".freeze
  s.version = "5.0.6".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/redis/redis-rb/issues", "changelog_uri" => "https://github.com/redis/redis-rb/blob/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/redis/5.0.6", "homepage_uri" => "https://github.com/redis/redis-rb", "source_code_uri" => "https://github.com/redis/redis-rb/tree/v5.0.6" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ezra Zygmuntowicz".freeze, "Taylor Weibley".freeze, "Matthew Clark".freeze, "Brian McKinney".freeze, "Salvatore Sanfilippo".freeze, "Luca Guidi".freeze, "Michel Martens".freeze, "Damian Janowski".freeze, "Pieter Noordhuis".freeze]
  s.date = "2023-01-16"
  s.description = "    A Ruby client that tries to match Redis' API one-to-one, while still\n    providing an idiomatic interface.\n".freeze
  s.email = ["redis-db@googlegroups.com".freeze]
  s.homepage = "https://github.com/redis/redis-rb".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A Ruby client library for Redis".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<redis-client>.freeze, [">= 0.9.0".freeze])
end
