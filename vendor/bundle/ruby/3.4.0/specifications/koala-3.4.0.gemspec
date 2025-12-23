# -*- encoding: utf-8 -*-
# stub: koala 3.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "koala".freeze
  s.version = "3.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alex Koppel".freeze]
  s.date = "2023-01-05"
  s.description = "Koala is a lightweight, flexible Ruby SDK for Facebook.  It allows read/write access to the social graph via the Graph and REST APIs, as well as support for realtime updates and OAuth and Facebook Connect authentication.  Koala is fully tested and supports Net::HTTP and Typhoeus connections out of the box and can accept custom modules for other services.".freeze
  s.email = "alex@alexkoppel.com".freeze
  s.extra_rdoc_files = ["readme.md".freeze, "changelog.md".freeze]
  s.files = ["changelog.md".freeze, "readme.md".freeze]
  s.homepage = "http://github.com/arsduo/koala".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--line-numbers".freeze, "--inline-source".freeze, "--title".freeze, "Koala".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1".freeze)
  s.rubygems_version = "3.2.32".freeze
  s.summary = "A lightweight, flexible library for Facebook with support for the Graph API, the REST API, realtime updates, and OAuth authentication.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<faraday-multipart>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<addressable>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<json>.freeze, [">= 1.8".freeze])
  s.add_runtime_dependency(%q<rexml>.freeze, [">= 0".freeze])
end
