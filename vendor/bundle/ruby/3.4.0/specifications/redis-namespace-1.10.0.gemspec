# -*- encoding: utf-8 -*-
# stub: redis-namespace 1.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "redis-namespace".freeze
  s.version = "1.10.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/resque/redis-namespace/issues", "changelog_uri" => "https://github.com/resque/redis-namespace/blob/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/redis-namespace/1.10.0", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Wanstrath".freeze, "Terence Lee".freeze, "Steve Klabnik".freeze, "Ryan Biesemeyer".freeze, "Mike Bianco".freeze]
  s.date = "2022-12-20"
  s.description = "Adds a Redis::Namespace class which can be used to namespace calls\nto Redis. This is useful when using a single instance of Redis with\nmultiple, different applications.\n".freeze
  s.email = ["chris@ozmm.org".freeze, "hone02@gmail.com".freeze, "steve@steveklabnik.com".freeze, "me@yaauie.com".freeze, "mike@mikebian.co".freeze]
  s.homepage = "https://github.com/resque/redis-namespace".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.3.15".freeze
  s.summary = "Namespaces Redis commands.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<redis>.freeze, [">= 4".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7".freeze])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<connection_pool>.freeze, [">= 0".freeze])
end
