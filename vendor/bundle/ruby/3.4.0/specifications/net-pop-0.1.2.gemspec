# -*- encoding: utf-8 -*-
# stub: net-pop 0.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "net-pop".freeze
  s.version = "0.1.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/ruby/net-pop", "source_code_uri" => "https://github.com/ruby/net-pop" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yukihiro Matsumoto".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-09-28"
  s.description = "Ruby client library for POP3.".freeze
  s.email = ["matz@ruby-lang.org".freeze]
  s.homepage = "https://github.com/ruby/net-pop".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.rubygems_version = "3.4.0.dev".freeze
  s.summary = "Ruby client library for POP3.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<net-protocol>.freeze, [">= 0".freeze])
end
