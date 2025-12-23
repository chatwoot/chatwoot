# -*- encoding: utf-8 -*-
# stub: dry-cli 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-cli".freeze
  s.version = "1.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-cli/issues", "changelog_uri" => "https://github.com/dry-rb/dry-cli/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-cli" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luca Guidi".freeze]
  s.date = "2024-07-14"
  s.description = "Common framework to build command line interfaces with Ruby".freeze
  s.email = ["me@lucaguidi.com".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-cli".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "Common framework to build command line interfaces with Ruby".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 1.6".freeze, "< 3".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.82".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.17.1".freeze])
end
