# -*- encoding: utf-8 -*-
# stub: working_hours 1.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "working_hours".freeze
  s.version = "1.4.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adrien Jarthon".freeze, "Intrepidd".freeze]
  s.date = "2021-07-15"
  s.description = "A modern ruby gem allowing to do time calculation with working hours.".freeze
  s.email = ["me@adrienjarthon.com".freeze, "adrien@siami.fr".freeze]
  s.homepage = "https://github.com/intrepidd/working_hours".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "time calculation with working hours".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.2".freeze])
  s.add_runtime_dependency(%q<tzinfo>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.5".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2".freeze])
  s.add_development_dependency(%q<timecop>.freeze, [">= 0".freeze])
end
