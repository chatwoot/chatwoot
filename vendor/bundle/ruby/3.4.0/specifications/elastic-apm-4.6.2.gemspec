# -*- encoding: utf-8 -*-
# stub: elastic-apm 4.6.2 ruby lib

Gem::Specification.new do |s|
  s.name = "elastic-apm".freeze
  s.version = "4.6.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "source_code_uri" => "https://github.com/elastic/apm-agent-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mikkel Malmberg".freeze, "Emily Stolfo".freeze]
  s.date = "2023-03-22"
  s.email = ["info@elastic.co".freeze]
  s.homepage = "https://github.com/elastic/apm-agent-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "The official Elastic APM agent for Ruby".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<http>.freeze, [">= 3.0".freeze])
  s.add_runtime_dependency(%q<ruby2_keywords>.freeze, [">= 0".freeze])
end
