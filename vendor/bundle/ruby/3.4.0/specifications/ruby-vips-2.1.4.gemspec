# -*- encoding: utf-8 -*-
# stub: ruby-vips 2.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-vips".freeze
  s.version = "2.1.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/libvips/ruby-vips/issues", "changelog_uri" => "https://github.com/libvips/ruby-vips/blob/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/ruby-vips", "homepage_uri" => "http://github.com/libvips/ruby-vips", "msys2_mingw_dependencies" => "libvips", "source_code_uri" => "https://github.com/libvips/ruby-vips" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Cupitt".freeze]
  s.date = "2021-11-20"
  s.description = "ruby-vips is a binding for the libvips image processing library. It is fast \n    and it can process large images without loading the whole image in memory.".freeze
  s.email = ["jcupitt@gmail.com".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze, "TODO".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze, "TODO".freeze]
  s.homepage = "http://github.com/libvips/ruby-vips".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.2.5".freeze
  s.summary = "A fast image processing library with low memory needs".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<ffi>.freeze, ["~> 1.12".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.3".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.11".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.0".freeze, "< 3".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0".freeze])
end
