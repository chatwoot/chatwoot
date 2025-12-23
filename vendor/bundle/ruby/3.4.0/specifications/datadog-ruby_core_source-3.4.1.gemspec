# -*- encoding: utf-8 -*-
# stub: datadog-ruby_core_source 3.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "datadog-ruby_core_source".freeze
  s.version = "3.4.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mark Moseley".freeze, "Gabriel Horner".freeze, "JetBrains RubyMine Team".freeze, "Datadog, Inc.".freeze]
  s.date = "2025-04-24"
  s.description = "Provide Ruby core source files for C extensions that need them.".freeze
  s.email = "dev@datadoghq.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/DataDog/datadog-ruby_core_source".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Provide Ruby core source files".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<archive-tar-minitar>.freeze, [">= 0.5.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0.9.2".freeze])
  s.add_development_dependency(%q<minitar-cli>.freeze, [">= 0".freeze])
end
