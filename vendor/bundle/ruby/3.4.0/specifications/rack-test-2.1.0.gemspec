# -*- encoding: utf-8 -*-
# stub: rack-test 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-test".freeze
  s.version = "2.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rack/rack-test/issues", "changelog_uri" => "https://github.com/rack/rack-test/blob/main/History.md", "mailing_list_uri" => "https://github.com/rack/rack-test/discussions", "source_code_uri" => "https://github.com/rack/rack-test" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jeremy Evans".freeze, "Bryan Helmkamp".freeze]
  s.date = "2023-03-14"
  s.description = "Rack::Test is a small, simple testing API for Rack apps. It can be used on its\nown or as a reusable starting point for Web frameworks and testing libraries\nto build on.".freeze
  s.email = ["code@jeremyevans.net".freeze, "bryan@brynary.com".freeze]
  s.homepage = "https://github.com/rack/rack-test".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Simple testing API built on Rack".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 1.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 5.0".freeze])
  s.add_development_dependency(%q<minitest-global_expectations>.freeze, [">= 0".freeze])
end
