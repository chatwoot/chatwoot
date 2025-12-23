# -*- encoding: utf-8 -*-
# stub: ast 2.4.3 ruby lib

Gem::Specification.new do |s|
  s.name = "ast".freeze
  s.version = "2.4.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["whitequark".freeze]
  s.date = "2025-03-19"
  s.description = "A library for working with Abstract Syntax Trees.".freeze
  s.email = ["whitequark@whitequark.org".freeze]
  s.homepage = "https://whitequark.github.io/ast/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.6.2".freeze
  s.summary = "A library for working with Abstract Syntax Trees.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 13.2".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.13".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.8.23".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<kramdown>.freeze, [">= 0".freeze])
end
