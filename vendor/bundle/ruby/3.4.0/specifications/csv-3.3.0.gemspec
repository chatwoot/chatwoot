# -*- encoding: utf-8 -*-
# stub: csv 3.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "csv".freeze
  s.version = "3.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Edward Gray II".freeze, "Kouhei Sutou".freeze]
  s.date = "2024-03-22"
  s.description = "The CSV library provides a complete interface to CSV files and data. It offers tools to enable you to read and write to and from Strings or IO objects, as needed.".freeze
  s.email = [nil, "kou@cozmixng.org".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "NEWS.md".freeze, "README.md".freeze, "doc/csv/recipes/filtering.rdoc".freeze, "doc/csv/recipes/generating.rdoc".freeze, "doc/csv/recipes/parsing.rdoc".freeze, "doc/csv/recipes/recipes.rdoc".freeze]
  s.files = ["LICENSE.txt".freeze, "NEWS.md".freeze, "README.md".freeze, "doc/csv/recipes/filtering.rdoc".freeze, "doc/csv/recipes/generating.rdoc".freeze, "doc/csv/recipes/parsing.rdoc".freeze, "doc/csv/recipes/recipes.rdoc".freeze]
  s.homepage = "https://github.com/ruby/csv".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.6.0.dev".freeze
  s.summary = "CSV Reading and Writing".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<benchmark_driver>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 3.4.8".freeze])
end
