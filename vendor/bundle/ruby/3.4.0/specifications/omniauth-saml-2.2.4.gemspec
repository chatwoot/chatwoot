# -*- encoding: utf-8 -*-
# stub: omniauth-saml 2.2.4 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-saml".freeze
  s.version = "2.2.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Raecoo Cao".freeze, "Ryan Wilcox".freeze, "Rajiv Aaron Manglani".freeze, "Steven Anderson".freeze, "Nikos Dimitrakopoulos".freeze, "Rudolf Vriend".freeze, "Bruno Pedro".freeze]
  s.date = "2025-05-27"
  s.description = "A generic SAML strategy for OmniAuth.".freeze
  s.homepage = "https://github.com/omniauth/omniauth-saml".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "A generic SAML strategy for OmniAuth.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<omniauth>.freeze, ["~> 2.1".freeze])
  s.add_runtime_dependency(%q<ruby-saml>.freeze, ["~> 1.18".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.2".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.13".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.10".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, ["~> 2.1".freeze])
  s.add_development_dependency(%q<conventional-changelog>.freeze, ["~> 1.3".freeze])
  s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.8".freeze])
end
