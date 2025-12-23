# -*- encoding: utf-8 -*-
# stub: domain_name 0.5.20190701 ruby lib

Gem::Specification.new do |s|
  s.name = "domain_name".freeze
  s.version = "0.5.20190701".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Akinori MUSHA".freeze]
  s.date = "2019-07-05"
  s.description = "This is a Domain Name manipulation library for Ruby.\n\nIt can also be used for cookie domain validation based on the Public\nSuffix List.\n".freeze
  s.email = ["knu@idaemons.org".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/knu/ruby-domain_name".freeze
  s.licenses = ["BSD-2-Clause".freeze, "BSD-3-Clause".freeze, "MPL-2.0".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Domain Name manipulation library for Ruby".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<unf>.freeze, [">= 0.0.5".freeze, "< 1.0.0".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, ["~> 2.5.5".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0.9.2.2".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 2.4.2".freeze])
end
