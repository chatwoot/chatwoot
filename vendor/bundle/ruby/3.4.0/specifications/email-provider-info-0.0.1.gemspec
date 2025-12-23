# -*- encoding: utf-8 -*-
# stub: email-provider-info 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "email-provider-info".freeze
  s.version = "0.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/fnando/email-provider-info/issues", "changelog_uri" => "https://github.com/fnando/email-provider-info/tree/v0.0.1/CHANGELOG.md", "documentation_uri" => "https://github.com/fnando/email-provider-info/tree/v0.0.1/README.md", "homepage_uri" => "https://github.com/fnando/email-provider-info", "license_uri" => "https://github.com/fnando/email-provider-info/tree/v0.0.1/LICENSE.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/fnando/email-provider-info/tree/v0.0.1" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nando Vieira".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-01-24"
  s.description = "Find email provider service based on the email address.".freeze
  s.email = ["me@fnando.com".freeze]
  s.homepage = "https://github.com/fnando/email-provider-info".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.3.3".freeze
  s.summary = "Find email provider service based on the email address.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-utils>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry-meta>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-fnando>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
end
