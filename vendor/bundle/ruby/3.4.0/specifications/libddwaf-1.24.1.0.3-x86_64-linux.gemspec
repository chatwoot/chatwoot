# -*- encoding: utf-8 -*-
# stub: libddwaf 1.24.1.0.3 x86_64-linux lib

Gem::Specification.new do |s|
  s.name = "libddwaf".freeze
  s.version = "1.24.1.0.3".freeze
  s.platform = "x86_64-linux".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 2.0.0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Datadog, Inc.".freeze]
  s.date = "2025-07-23"
  s.description = "libddwaf packages a WAF implementation in C++, exposed to Ruby\n".freeze
  s.email = ["dev@datadoghq.com".freeze]
  s.homepage = "https://github.com/DataDog/libddwaf-rb".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.5.21".freeze
  s.summary = "Datadog WAF".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<ffi>.freeze, ["~> 1.0".freeze])
end
