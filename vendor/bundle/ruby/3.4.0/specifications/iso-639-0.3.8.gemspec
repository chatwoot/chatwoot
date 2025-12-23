# -*- encoding: utf-8 -*-
# stub: iso-639 0.3.8 ruby lib

Gem::Specification.new do |s|
  s.name = "iso-639".freeze
  s.version = "0.3.8".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["William Melody".freeze]
  s.date = "2024-10-07"
  s.description = "ISO 639-1 and ISO 639-2 language code entries and convenience methods.".freeze
  s.email = "hi@williammelody.com".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "http://github.com/xwmx/iso-639".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "ISO 639-1 and ISO 639-2 language code entries and convenience methods.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<csv>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5".freeze, ">= 0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 1".freeze, ">= 0".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, ["~> 6".freeze, ">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0".freeze, ">= 0.49.0".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, ["~> 3".freeze, ">= 0".freeze])
end
