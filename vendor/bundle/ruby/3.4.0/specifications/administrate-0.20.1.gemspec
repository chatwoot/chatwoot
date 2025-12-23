# -*- encoding: utf-8 -*-
# stub: administrate 0.20.1 ruby lib

Gem::Specification.new do |s|
  s.name = "administrate".freeze
  s.version = "0.20.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nick Charlton".freeze, "Grayson Wright".freeze]
  s.date = "2024-01-24"
  s.description = "Administrate is heavily inspired by projects like Rails Admin and ActiveAdmin,\nbut aims to provide a better user experience for site admins,\nand to be easier for developers to customize.\n\nTo do that, we're following a few simple rules:\n\n- No DSLs (domain-specific languages)\n- Support the simplest use cases,\n  and let the user override defaults with standard tools\n  such as plain Rails controllers and views.\n- Break up the library into core components and plugins,\n  so each component stays small and easy to maintain.\n".freeze
  s.email = ["nick@nickcharlton.net".freeze, "grayson@thoughtbot.com".freeze]
  s.homepage = "https://administrate-demo.herokuapp.com/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A Rails engine for creating super-flexible admin dashboards".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 6.0".freeze, "< 8.0".freeze])
  s.add_runtime_dependency(%q<actionview>.freeze, [">= 6.0".freeze, "< 8.0".freeze])
  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.0".freeze, "< 8.0".freeze])
  s.add_runtime_dependency(%q<jquery-rails>.freeze, ["~> 4.6.0".freeze])
  s.add_runtime_dependency(%q<kaminari>.freeze, ["~> 1.2.2".freeze])
  s.add_runtime_dependency(%q<sassc-rails>.freeze, ["~> 2.1".freeze])
  s.add_runtime_dependency(%q<selectize-rails>.freeze, ["~> 0.6".freeze])
end
