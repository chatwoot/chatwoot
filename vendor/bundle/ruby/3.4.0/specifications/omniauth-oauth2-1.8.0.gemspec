# -*- encoding: utf-8 -*-
# stub: omniauth-oauth2 1.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-oauth2".freeze
  s.version = "1.8.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bleigh".freeze, "Erik Michaels-Ober".freeze, "Tom Milewski".freeze]
  s.date = "2022-06-18"
  s.description = "An abstract OAuth2 strategy for OmniAuth.".freeze
  s.email = ["michael@intridea.com".freeze, "sferik@gmail.com".freeze, "tmilewski@gmail.com".freeze]
  s.homepage = "https://github.com/omniauth/omniauth-oauth2".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.32".freeze
  s.summary = "An abstract OAuth2 strategy for OmniAuth.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<oauth2>.freeze, [">= 1.4".freeze, "< 3".freeze])
  s.add_runtime_dependency(%q<omniauth>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
end
