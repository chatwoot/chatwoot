# -*- encoding: utf-8 -*-
# stub: bindex 0.8.1 ruby lib
# stub: ext/skiptrace/extconf.rb

Gem::Specification.new do |s|
  s.name = "bindex".freeze
  s.version = "0.8.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Genadi Samokovarov".freeze]
  s.date = "2019-07-10"
  s.email = ["gsamokovarov@gmail.com".freeze]
  s.extensions = ["ext/skiptrace/extconf.rb".freeze]
  s.files = ["ext/skiptrace/extconf.rb".freeze]
  s.homepage = "https://github.com/gsamokovarov/bindex".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Bindings for your Ruby exceptions".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.4".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0".freeze])
end
