# -*- encoding: utf-8 -*-
# stub: html2text 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "html2text".freeze
  s.version = "0.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jevon Wright".freeze]
  s.date = "2024-06-08"
  s.description = "A Ruby component to convert HTML into a plain text format.".freeze
  s.email = ["jevon@jevon.org".freeze]
  s.homepage = "https://github.com/soundasleep/html2text_ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "3.5.9".freeze
  s.summary = "Convert HTML into plain text.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.0".freeze, "< 2.0".freeze])
  s.add_development_dependency(%q<bundler-audit>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<colorize>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-collection_matchers>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rake>.freeze, [">= 0".freeze])
end
