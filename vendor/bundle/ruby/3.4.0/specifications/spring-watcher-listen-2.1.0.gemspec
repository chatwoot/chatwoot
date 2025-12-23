# -*- encoding: utf-8 -*-
# stub: spring-watcher-listen 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "spring-watcher-listen".freeze
  s.version = "2.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jon Leighton".freeze]
  s.date = "2022-09-23"
  s.email = ["j@jonathanleighton.com".freeze]
  s.homepage = "https://github.com/jonleighton/spring-watcher-listen".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Makes spring watch files using the listen gem.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<spring>.freeze, [">= 4".freeze])
  s.add_runtime_dependency(%q<listen>.freeze, [">= 2.7".freeze, "< 4.0".freeze])
end
