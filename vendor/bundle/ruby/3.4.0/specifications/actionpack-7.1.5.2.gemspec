# -*- encoding: utf-8 -*-
# stub: actionpack 7.1.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "actionpack".freeze
  s.version = "7.1.5.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v7.1.5.2/actionpack/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v7.1.5.2/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rails/rails/tree/v7.1.5.2/actionpack" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "1980-01-02"
  s.description = "Web apps on Rails. Simple, battle-tested conventions for building and testing MVC web applications. Works with any Rack-compatible server.".freeze
  s.email = "david@loudthinking.com".freeze
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.requirements = ["none".freeze]
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Web-flow and rendering framework putting the VC in MVC (part of Rails).".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, ["= 7.1.5.2".freeze])
  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.8.5".freeze])
  s.add_runtime_dependency(%q<racc>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 2.2.4".freeze])
  s.add_runtime_dependency(%q<rack-session>.freeze, [">= 1.0.1".freeze])
  s.add_runtime_dependency(%q<rack-test>.freeze, [">= 0.6.3".freeze])
  s.add_runtime_dependency(%q<rails-html-sanitizer>.freeze, ["~> 1.6".freeze])
  s.add_runtime_dependency(%q<rails-dom-testing>.freeze, ["~> 2.2".freeze])
  s.add_runtime_dependency(%q<actionview>.freeze, ["= 7.1.5.2".freeze])
  s.add_development_dependency(%q<activemodel>.freeze, ["= 7.1.5.2".freeze])
end
