# -*- encoding: utf-8 -*-
# stub: devise 4.9.4 ruby lib

Gem::Specification.new do |s|
  s.name = "devise".freeze
  s.version = "4.9.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/heartcombo/devise/issues", "changelog_uri" => "https://github.com/heartcombo/devise/blob/main/CHANGELOG.md", "documentation_uri" => "https://rubydoc.info/github/heartcombo/devise", "homepage_uri" => "https://github.com/heartcombo/devise", "source_code_uri" => "https://github.com/heartcombo/devise", "wiki_uri" => "https://github.com/heartcombo/devise/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jos\u00E9 Valim".freeze, "Carlos Ant\u00F4nio".freeze]
  s.date = "2024-04-10"
  s.description = "Flexible authentication solution for Rails with Warden".freeze
  s.email = "heartcombo@googlegroups.com".freeze
  s.homepage = "https://github.com/heartcombo/devise".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\n[DEVISE] Please review the [changelog] and [upgrade guide] for more info on Hotwire / Turbo integration.\n\n  [changelog] https://github.com/heartcombo/devise/blob/main/CHANGELOG.md\n  [upgrade guide] https://github.com/heartcombo/devise/wiki/How-To:-Upgrade-to-Devise-4.9.0-%5BHotwire-Turbo-integration%5D\n  ".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Flexible authentication solution for Rails with Warden".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<warden>.freeze, ["~> 1.2.3".freeze])
  s.add_runtime_dependency(%q<orm_adapter>.freeze, ["~> 0.1".freeze])
  s.add_runtime_dependency(%q<bcrypt>.freeze, ["~> 3.0".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 4.1.0".freeze])
  s.add_runtime_dependency(%q<responders>.freeze, [">= 0".freeze])
end
