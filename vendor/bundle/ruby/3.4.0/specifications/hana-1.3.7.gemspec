# -*- encoding: utf-8 -*-
# stub: hana 1.3.7 ruby lib

Gem::Specification.new do |s|
  s.name = "hana".freeze
  s.version = "1.3.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "http://github.com/tenderlove/hana" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Aaron Patterson".freeze]
  s.date = "2020-12-03"
  s.description = "Implementation of [JSON Patch][1] and [JSON Pointer][2] RFC.".freeze
  s.email = ["aaron@tenderlovemaking.com".freeze]
  s.extra_rdoc_files = ["Manifest.txt".freeze, "README.md".freeze]
  s.files = ["Manifest.txt".freeze, "README.md".freeze]
  s.homepage = "http://github.com/tenderlove/hana".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.2.0.rc.2".freeze
  s.summary = "Implementation of [JSON Patch][1] and [JSON Pointer][2] RFC.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.14".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0".freeze, "< 7".freeze])
  s.add_development_dependency(%q<hoe>.freeze, ["~> 3.22".freeze])
end
