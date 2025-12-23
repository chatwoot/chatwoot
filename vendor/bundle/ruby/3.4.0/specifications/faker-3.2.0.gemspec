# -*- encoding: utf-8 -*-
# stub: faker 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "faker".freeze
  s.version = "3.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/faker-ruby/faker/issues", "changelog_uri" => "https://github.com/faker-ruby/faker/blob/main/CHANGELOG.md", "documentation_uri" => "https://rubydoc.info/github/faker-ruby/faker", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/faker-ruby/faker", "yard.run" => "yri" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Benjamin Curtis".freeze, "Vitor Oliveira".freeze]
  s.date = "2023-04-14"
  s.description = "Faker, a port of Data::Faker from Perl, is used to easily generate fake data: names, addresses, phone numbers, etc.".freeze
  s.email = ["benjamin.curtis@gmail.com".freeze, "vbrazo@gmail.com".freeze]
  s.executables = ["faker".freeze]
  s.files = ["bin/faker".freeze]
  s.homepage = "https://github.com/faker-ruby/faker".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Easily generate fake data".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<i18n>.freeze, [">= 1.8.11".freeze, "< 2".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["= 5.18.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["= 0.14.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["= 13.0.6".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 1.50.1".freeze])
  s.add_development_dependency(%q<rubocop-minitest>.freeze, ["= 0.30.0".freeze])
  s.add_development_dependency(%q<rubocop-rake>.freeze, ["= 0.6.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["= 0.22.0".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, ["= 3.5.7".freeze])
  s.add_development_dependency(%q<timecop>.freeze, ["= 0.9.6".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["= 0.9.34".freeze])
end
