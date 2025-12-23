# -*- encoding: utf-8 -*-
# stub: mime-types 3.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "mime-types".freeze
  s.version = "3.4.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/mime-types/ruby-mime-types/issues", "changelog_uri" => "https://github.com/mime-types/ruby-mime-types/blob/master/History.md", "homepage_uri" => "https://github.com/mime-types/ruby-mime-types/", "source_code_uri" => "https://github.com/mime-types/ruby-mime-types/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Austin Ziegler".freeze]
  s.date = "2021-11-16"
  s.description = "The mime-types library provides a library and registry for information about\nMIME content type definitions. It can be used to determine defined filename\nextensions for MIME types, or to use filename extensions to look up the likely\nMIME type definitions.\n\nVersion 3.0 is a major release that requires Ruby 2.0 compatibility and removes\ndeprecated functions. The columnar registry format introduced in 2.6 has been\nmade the primary format; the registry data has been extracted from this library\nand put into {mime-types-data}[https://github.com/mime-types/mime-types-data].\nAdditionally, mime-types is now licensed exclusively under the MIT licence and\nthere is a code of conduct in effect. There are a number of other smaller\nchanges described in the History file.".freeze
  s.email = ["halostatue@gmail.com".freeze]
  s.extra_rdoc_files = ["Code-of-Conduct.md".freeze, "Contributing.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.files = ["Code-of-Conduct.md".freeze, "Contributing.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.homepage = "https://github.com/mime-types/ruby-mime-types/".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "The mime-types library provides a library and registry for information about MIME content type definitions".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<mime-types-data>.freeze, ["~> 3.2015".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.14".freeze])
  s.add_development_dependency(%q<hoe-doofus>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<hoe-gemspec2>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<hoe-git>.freeze, ["~> 1.6".freeze])
  s.add_development_dependency(%q<hoe-rubygems>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest-autotest>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest-focus>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest-bonus-assertions>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<minitest-hooks>.freeze, ["~> 1.4".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 10.0".freeze, "< 14.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.7".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0".freeze, "< 7".freeze])
  s.add_development_dependency(%q<hoe>.freeze, ["~> 3.23".freeze])
end
