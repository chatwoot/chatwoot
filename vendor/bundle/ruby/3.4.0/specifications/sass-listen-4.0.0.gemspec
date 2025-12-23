# -*- encoding: utf-8 -*-
# stub: sass-listen 4.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "sass-listen".freeze
  s.version = "4.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thibaud Guillaume-Gentil".freeze]
  s.date = "2017-07-13"
  s.description = "This fork of guard/listen provides a stable API for users of the ruby Sass CLI".freeze
  s.email = "thibaud@thibaud.gg".freeze
  s.homepage = "https://github.com/sass/listen".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.6.11".freeze
  s.summary = "Fork of guard/listen".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rb-fsevent>.freeze, ["~> 0.9".freeze, ">= 0.9.4".freeze])
  s.add_runtime_dependency(%q<rb-inotify>.freeze, ["~> 0.9".freeze, ">= 0.9.7".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.3.5".freeze])
end
