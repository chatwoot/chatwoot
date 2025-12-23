# -*- encoding: utf-8 -*-
# stub: google-cloud-storage 1.52.0 ruby lib

Gem::Specification.new do |s|
  s.name = "google-cloud-storage".freeze
  s.version = "1.52.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Moore".freeze, "Chris Smith".freeze]
  s.date = "2024-05-31"
  s.description = "google-cloud-storage is the official library for Google Cloud Storage.".freeze
  s.email = ["mike@blowmage.com".freeze, "quartzmo@gmail.com".freeze]
  s.homepage = "https://github.com/googleapis/google-cloud-ruby/tree/master/google-cloud-storage".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.5.6".freeze
  s.summary = "API Client library for Google Cloud Storage".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<google-cloud-core>.freeze, ["~> 1.6".freeze])
  s.add_runtime_dependency(%q<google-apis-core>.freeze, ["~> 0.13".freeze])
  s.add_runtime_dependency(%q<google-apis-iamcredentials_v1>.freeze, ["~> 0.18".freeze])
  s.add_runtime_dependency(%q<google-apis-storage_v1>.freeze, ["~> 0.38".freeze])
  s.add_runtime_dependency(%q<googleauth>.freeze, ["~> 1.9".freeze])
  s.add_runtime_dependency(%q<digest-crc>.freeze, ["~> 0.4".freeze])
  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.8".freeze])
  s.add_runtime_dependency(%q<mini_mime>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<google-style>.freeze, ["~> 1.25.1".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.16".freeze])
  s.add_development_dependency(%q<minitest-autotest>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest-focus>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<minitest-rg>.freeze, ["~> 5.2".freeze])
  s.add_development_dependency(%q<autotest-suffix>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<redcarpet>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.9".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9".freeze])
  s.add_development_dependency(%q<yard-doctest>.freeze, ["~> 0.1.13".freeze])
  s.add_development_dependency(%q<retriable>.freeze, ["~> 3.1.2".freeze])
end
