# -*- encoding: utf-8 -*-
# stub: ruby-saml 1.18.1 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-saml".freeze
  s.version = "1.18.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["SAML Toolkit".freeze, "Sixto Martin".freeze]
  s.date = "2025-07-29"
  s.description = "SAML Ruby toolkit. Add SAML support to your Ruby software using this library".freeze
  s.email = ["contact@iamdigitalservices.com".freeze, "sixto.martin.garcia@gmail.com".freeze]
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://github.com/saml-toolkits/ruby-saml".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "3.5.18".freeze
  s.summary = "SAML Ruby Tookit".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.13.10".freeze])
  s.add_runtime_dependency(%q<rexml>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["< 0.22.0".freeze])
  s.add_development_dependency(%q<simplecov-lcov>.freeze, ["> 0.7.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.5".freeze, "< 5.19.0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 0.14".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3".freeze])
  s.add_development_dependency(%q<shoulda>.freeze, ["~> 2.11".freeze])
  s.add_development_dependency(%q<systemu>.freeze, ["~> 2".freeze])
  s.add_development_dependency(%q<timecop>.freeze, ["~> 0.9".freeze])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0".freeze])
end
