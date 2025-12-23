# -*- encoding: utf-8 -*-
# stub: orm_adapter 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "orm_adapter".freeze
  s.version = "0.5.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ian White".freeze, "Jose Valim".freeze]
  s.date = "2013-11-12"
  s.description = "Provides a single point of entry for using basic features of ruby ORMs".freeze
  s.email = "ian.w.white@gmail.com".freeze
  s.homepage = "http://github.com/ianwhite/orm_adapter".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.0.6".freeze
  s.summary = "orm_adapter provides a single point of entry for using basic features of popular ruby ORMs.  Its target audience is gem authors who want to support many ruby ORMs.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 1.0.0".freeze])
  s.add_development_dependency(%q<git>.freeze, [">= 1.2.5".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0.6.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0.8.7".freeze])
  s.add_development_dependency(%q<activerecord>.freeze, [">= 3.2.15".freeze])
  s.add_development_dependency(%q<mongoid>.freeze, ["~> 2.8.0".freeze])
  s.add_development_dependency(%q<mongo_mapper>.freeze, ["~> 0.11.0".freeze])
  s.add_development_dependency(%q<bson_ext>.freeze, [">= 1.3.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 2.4.0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 1.3.2".freeze])
  s.add_development_dependency(%q<datamapper>.freeze, [">= 1.0".freeze])
  s.add_development_dependency(%q<dm-sqlite-adapter>.freeze, [">= 1.0".freeze])
  s.add_development_dependency(%q<dm-active_model>.freeze, [">= 1.0".freeze])
end
