# -*- encoding: utf-8 -*-
# stub: http-cookie 1.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "http-cookie".freeze
  s.version = "1.0.5".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Akinori MUSHA".freeze, "Aaron Patterson".freeze, "Eric Hodel".freeze, "Mike Dalessio".freeze]
  s.date = "2022-05-25"
  s.description = "HTTP::Cookie is a Ruby library to handle HTTP Cookies based on RFC 6265.  It has with security, standards compliance and compatibility in mind, to behave just the same as today's major web browsers.  It has builtin support for the legacy cookies.txt and the latest cookies.sqlite formats of Mozilla Firefox, and its modular API makes it easy to add support for a new backend store.".freeze
  s.email = ["knu@idaemons.org".freeze, "aaronp@rubyforge.org".freeze, "drbrain@segment7.net".freeze, "mike.dalessio@gmail.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE.txt".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/sparklemotion/http-cookie".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.14".freeze
  s.summary = "A Ruby library to handle HTTP Cookies based on RFC 6265".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<domain_name>.freeze, ["~> 0.5".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.2.0".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 2.4.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0.9.2.2".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, ["> 2.4.2".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
end
