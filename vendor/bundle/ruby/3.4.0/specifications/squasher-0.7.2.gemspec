# -*- encoding: utf-8 -*-
# stub: squasher 0.7.2 ruby lib

Gem::Specification.new do |s|
  s.name = "squasher".freeze
  s.version = "0.7.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sergey Pchelintsev".freeze]
  s.date = "2023-03-07"
  s.description = "Squash your old migrations".freeze
  s.email = ["linz.sergey@gmail.com".freeze]
  s.executables = ["squasher".freeze]
  s.files = ["bin/squasher".freeze]
  s.homepage = "https://github.com/jalkoby/squasher".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Squash your old migrations".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 1.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.3.0".freeze])
end
