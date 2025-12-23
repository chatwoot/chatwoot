# -*- encoding: utf-8 -*-
# stub: factory_bot_rails 6.4.3 ruby lib

Gem::Specification.new do |s|
  s.name = "factory_bot_rails".freeze
  s.version = "6.4.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/thoughtbot/factory_bot_rails/blob/main/NEWS.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Joe Ferris".freeze]
  s.date = "2023-12-30"
  s.description = "factory_bot_rails provides integration between factory_bot and rails 5.0 or newer".freeze
  s.email = "jferris@thoughtbot.com".freeze
  s.homepage = "https://github.com/thoughtbot/factory_bot_rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "factory_bot_rails provides integration between factory_bot and rails 5.0 or newer".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<factory_bot>.freeze, ["~> 6.4".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.0.0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<activerecord>.freeze, [">= 5.0.0".freeze])
end
