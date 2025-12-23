# -*- encoding: utf-8 -*-
# stub: reverse_markdown 2.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "reverse_markdown".freeze
  s.version = "2.1.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Johannes Opper".freeze]
  s.date = "2021-10-31"
  s.description = "Map simple html back into markdown, e.g. if you want to import existing html data in your application.".freeze
  s.email = ["johannes.opper@gmail.com".freeze]
  s.executables = ["reverse_markdown".freeze]
  s.files = ["bin/reverse_markdown".freeze]
  s.homepage = "http://github.com/xijo/reverse_markdown".freeze
  s.licenses = ["WTFPL".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Convert html code into markdown.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<kramdown>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<byebug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<codeclimate-test-reporter>.freeze, [">= 0".freeze])
end
