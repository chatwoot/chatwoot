# -*- encoding: utf-8 -*-
# stub: uglifier 4.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "uglifier".freeze
  s.version = "4.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ville Lautanala".freeze]
  s.date = "2019-09-25"
  s.description = "Uglifier minifies JavaScript files by wrapping UglifyJS to be accessible in Ruby".freeze
  s.email = ["lautis@gmail.com".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze, "CHANGELOG.md".freeze, "CONTRIBUTING.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "CONTRIBUTING.md".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "http://github.com/lautis/uglifier".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Ruby wrapper for UglifyJS JavaScript compressor".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<execjs>.freeze, [">= 0.3.0".freeze, "< 3".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.3".freeze])
  s.add_development_dependency(%q<sourcemap>.freeze, ["~> 0.1.1".freeze])
end
