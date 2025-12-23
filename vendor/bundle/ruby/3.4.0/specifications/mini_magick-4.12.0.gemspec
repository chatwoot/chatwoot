# -*- encoding: utf-8 -*-
# stub: mini_magick 4.12.0 ruby lib

Gem::Specification.new do |s|
  s.name = "mini_magick".freeze
  s.version = "4.12.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Corey Johnson".freeze, "Hampton Catlin".freeze, "Peter Kieltyka".freeze, "James Miller".freeze, "Thiago Fernandes Massa".freeze, "Janko Marohni\u0107".freeze]
  s.date = "2022-12-07"
  s.description = "Manipulate images with minimal use of memory via ImageMagick / GraphicsMagick".freeze
  s.email = ["probablycorey@gmail.com".freeze, "hcatlin@gmail.com".freeze, "peter@nulayer.com".freeze, "bensie@gmail.com".freeze, "thiagown@gmail.com".freeze, "janko.marohnic@gmail.com".freeze]
  s.homepage = "https://github.com/minimagick/minimagick".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.requirements = ["You must have ImageMagick or GraphicsMagick installed".freeze]
  s.rubygems_version = "3.3.3".freeze
  s.summary = "Manipulate images with minimal use of memory via ImageMagick / GraphicsMagick".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5.0".freeze])
  s.add_development_dependency(%q<guard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<posix-spawn>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
end
