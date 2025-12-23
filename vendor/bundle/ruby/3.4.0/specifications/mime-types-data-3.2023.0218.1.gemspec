# -*- encoding: utf-8 -*-
# stub: mime-types-data 3.2023.0218.1 ruby lib

Gem::Specification.new do |s|
  s.name = "mime-types-data".freeze
  s.version = "3.2023.0218.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Austin Ziegler".freeze]
  s.date = "2023-02-18"
  s.description = "mime-types-data provides a registry for information about MIME media type\ndefinitions. It can be used with the Ruby mime-types library or other software\nto determine defined filename extensions for MIME types, or to use filename\nextensions to look up the likely MIME type definitions.".freeze
  s.email = ["halostatue@gmail.com".freeze]
  s.extra_rdoc_files = ["Code-of-Conduct.md".freeze, "Contributing.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.md".freeze]
  s.files = ["Code-of-Conduct.md".freeze, "Contributing.md".freeze, "History.md".freeze, "Licence.md".freeze, "Manifest.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/mime-types/mime-types-data/".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.4.7".freeze
  s.summary = "mime-types-data provides a registry for information about MIME media type definitions".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.6".freeze])
  s.add_development_dependency(%q<hoe-doofus>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<hoe-gemspec2>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<hoe-git2>.freeze, ["~> 1.7".freeze])
  s.add_development_dependency(%q<hoe-rubygems>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 10.0".freeze, "< 14".freeze])
  s.add_development_dependency(%q<mime-types>.freeze, [">= 3.4.0".freeze, "< 4".freeze])
  s.add_development_dependency(%q<standardrb>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<psych>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0".freeze, "< 7".freeze])
  s.add_development_dependency(%q<hoe>.freeze, ["~> 4.0".freeze])
end
