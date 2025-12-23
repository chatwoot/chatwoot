# -*- encoding: utf-8 -*-
# stub: meta_request 0.8.3 ruby lib

Gem::Specification.new do |s|
  s.name = "meta_request".freeze
  s.version = "0.8.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dejan Simic".freeze]
  s.date = "2024-09-02"
  s.description = "Supporting gem for Rails Panel (Google Chrome extension for Rails development)".freeze
  s.email = "desimic@gmail.com".freeze
  s.homepage = "https://github.com/dejan/rails_panel/tree/master/meta_request".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.26".freeze
  s.summary = "Request your Rails request".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack-contrib>.freeze, [">= 1.1".freeze, "< 3".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 3.0.0".freeze, "< 8".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.74.0".freeze])
end
