# -*- encoding: utf-8 -*-
# stub: seed_dump 3.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "seed_dump".freeze
  s.version = "3.3.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rob Halff".freeze, "Ryan Oblak".freeze]
  s.date = "2018-05-08"
  s.description = "Dump (parts) of your database to db/seeds.rb to get a headstart creating a meaningful seeds.rb file".freeze
  s.email = "rroblak@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/rroblak/seed_dump".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "{Seed Dumper for Rails}".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4".freeze])
  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4".freeze])
  s.add_development_dependency(%q<byebug>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<factory_bot>.freeze, ["~> 4.8.2".freeze])
  s.add_development_dependency(%q<activerecord-import>.freeze, ["~> 0.4".freeze])
  s.add_development_dependency(%q<jeweler>.freeze, ["~> 2.0".freeze])
end
