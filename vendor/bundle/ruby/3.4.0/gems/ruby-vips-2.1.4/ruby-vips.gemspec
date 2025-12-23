# frozen_string_literal: true

require_relative "lib/vips/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-vips"
  spec.version = Vips::VERSION
  spec.summary = "A fast image processing library with low memory needs"
  spec.description = <<-DESC.strip
    ruby-vips is a binding for the libvips image processing library. It is fast 
    and it can process large images without loading the whole image in memory.
  DESC
  spec.homepage = "http://github.com/libvips/ruby-vips"
  spec.licenses = ["MIT"]
  spec.authors = ["John Cupitt"]
  spec.email = ["jcupitt@gmail.com"]

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/libvips/ruby-vips/issues",
    "changelog_uri" =>
      "https://github.com/libvips/ruby-vips/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/ruby-vips",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/libvips/ruby-vips",

    "msys2_mingw_dependencies" => "libvips"
  }

  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = %w[LICENSE.txt README.md TODO]

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.required_ruby_version = ">= 2.0.0"

  spec.add_runtime_dependency "ffi", ["~> 1.12"]

  spec.add_development_dependency "rake", ["~> 12.0"]
  spec.add_development_dependency "rspec", ["~> 3.3"]
  spec.add_development_dependency "yard", ["~> 0.9.11"]
  spec.add_development_dependency "bundler", [">= 1.0", "< 3"]

  if Gem.ruby_version >= Gem::Version.new("2.2")
    spec.add_development_dependency "standard"
  end
end
