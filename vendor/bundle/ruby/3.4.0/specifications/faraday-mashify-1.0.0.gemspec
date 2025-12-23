# -*- encoding: utf-8 -*-
# stub: faraday-mashify 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "faraday-mashify".freeze
  s.version = "1.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/sue445/faraday-mashify/issues", "changelog_uri" => "https://github.com/sue445/faraday-mashify/blob/v1.0.0/CHANGELOG.md", "documentation_uri" => "https://sue445.github.io/faraday-mashify/", "homepage_uri" => "https://github.com/sue445/faraday-mashify", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/sue445/faraday-mashify", "wiki_uri" => "https://github.com/sue445/faraday-mashify/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["sue445".freeze]
  s.date = "2025-03-24"
  s.description = "Faraday middleware for wrapping responses into Hashie::Mash.\n".freeze
  s.email = ["sue445@sue445.net".freeze]
  s.homepage = "https://github.com/sue445/faraday-mashify".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.7".freeze, "< 4".freeze])
  s.rubygems_version = "3.5.22".freeze
  s.summary = "Faraday middleware for wrapping responses into Hashie::Mash".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<hashie>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21.0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.74".freeze])
  s.add_development_dependency(%q<rubocop_auto_corrector>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-packaging>.freeze, ["~> 0.6".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 3.5".freeze])
end
