# -*- encoding: utf-8 -*-
# stub: sidekiq-cron 1.12.0 ruby lib

Gem::Specification.new do |s|
  s.name = "sidekiq-cron".freeze
  s.version = "1.12.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ondrej Bartas".freeze]
  s.date = "2023-12-08"
  s.description = "Enables to set jobs to be run in specified time (using CRON notation or natural language)".freeze
  s.email = "ondrej@bartas.cz".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/sidekiq-cron/sidekiq-cron".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Scheduler/Cron for Sidekiq jobs".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<fugit>.freeze, ["~> 1.8".freeze])
  s.add_runtime_dependency(%q<sidekiq>.freeze, [">= 6".freeze])
  s.add_runtime_dependency(%q<globalid>.freeze, [">= 1.0.1".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.15".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 2.1".freeze])
  s.add_development_dependency(%q<rack>.freeze, ["~> 2.2".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21".freeze])
  s.add_development_dependency(%q<simplecov-cobertura>.freeze, ["~> 2.1".freeze])
end
