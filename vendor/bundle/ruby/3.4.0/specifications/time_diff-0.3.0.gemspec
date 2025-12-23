# -*- encoding: utf-8 -*-
# stub: time_diff 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "time_diff".freeze
  s.version = "0.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["abhilash".freeze]
  s.date = "2012-11-13"
  s.description = "It returns a hash file with the difference in terms of year, month, week, day, hour, minute and second".freeze
  s.email = "abhidsm@gmail.com".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README".freeze, "README.rdoc".freeze]
  s.files = ["LICENSE.txt".freeze, "README".freeze, "README.rdoc".freeze]
  s.homepage = "http://github.com/abhidsm/time_diff".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "1.8.6".freeze
  s.summary = "Gem to get the difference between two time".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 3

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<i18n>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<shoulda>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.0.0".freeze])
  s.add_development_dependency(%q<jeweler>.freeze, ["~> 1.5.2".freeze])
  s.add_development_dependency(%q<rcov>.freeze, [">= 0".freeze])
end
