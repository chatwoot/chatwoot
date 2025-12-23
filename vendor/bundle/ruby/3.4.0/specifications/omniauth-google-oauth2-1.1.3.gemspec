# -*- encoding: utf-8 -*-
# stub: omniauth-google-oauth2 1.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-google-oauth2".freeze
  s.version = "1.1.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Josh Ellithorpe".freeze, "Yury Korolev".freeze]
  s.date = "2024-08-30"
  s.description = "A Google OAuth2 strategy for OmniAuth 1.x. This allows you to login to Google with your ruby app.".freeze
  s.email = ["quest@mac.com".freeze]
  s.homepage = "https://github.com/zquestz/omniauth-google-oauth2".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "A Google OAuth2 strategy for OmniAuth 1.x".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<jwt>.freeze, [">= 2.0".freeze])
  s.add_runtime_dependency(%q<oauth2>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<omniauth>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<omniauth-oauth2>.freeze, ["~> 1.8".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.6".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.49".freeze])
end
