# -*- encoding: utf-8 -*-
# stub: browser 5.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "browser".freeze
  s.version = "5.3.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/fnando/browser/blob/main/CHANGELOG.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nando Vieira".freeze]
  s.date = "2021-02-22"
  s.description = "Do some browser detection with Ruby.".freeze
  s.email = ["fnando.vieira@gmail.com".freeze]
  s.homepage = "https://github.com/fnando/browser".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.2.3".freeze
  s.summary = "Do some browser detection with Ruby.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-autotest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-utils>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry-meta>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-fnando>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
end
