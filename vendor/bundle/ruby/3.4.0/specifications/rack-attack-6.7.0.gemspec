# -*- encoding: utf-8 -*-
# stub: rack-attack 6.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-attack".freeze
  s.version = "6.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rack/rack-attack/issues", "changelog_uri" => "https://github.com/rack/rack-attack/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/rack/rack-attack" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Aaron Suggs".freeze]
  s.date = "2023-07-26"
  s.description = "A rack middleware for throttling and blocking abusive requests".freeze
  s.email = "aaron@ktheory.com".freeze
  s.homepage = "https://github.com/rack/rack-attack".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Block & throttle abusive requests".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 1.0".freeze, "< 4".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.2".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.17".freeze, "< 3.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.11".freeze])
  s.add_development_dependency(%q<minitest-stub-const>.freeze, ["~> 0.6".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 0.89.1".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.5.0".freeze])
  s.add_development_dependency(%q<timecop>.freeze, ["~> 0.9.1".freeze])
  s.add_development_dependency(%q<byebug>.freeze, ["~> 11.0".freeze])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 0".freeze])
end
