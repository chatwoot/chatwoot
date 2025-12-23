require File.expand_path("../lib/image_processing/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "image_processing"
  spec.version       = ImageProcessing::VERSION

  spec.required_ruby_version = ">= 2.3"

  spec.summary       = "High-level wrapper for processing images for the web with ImageMagick or libvips."
  spec.description   = "High-level wrapper for processing images for the web with ImageMagick or libvips."
  spec.homepage      = "https://github.com/janko/image_processing"
  spec.authors       = ["Janko Marohnić"]
  spec.email         = ["janko.marohnic@gmail.com"]
  spec.license       = "MIT"

  spec.files         = Dir["README.md", "LICENSE.txt", "CHANGELOG.md", "lib/**/*.rb", "*.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "mini_magick", ">= 4.9.5", "< 5"
  spec.add_dependency "ruby-vips", ">= 2.0.17", "< 3"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.8"
  spec.add_development_dependency "minitest-hooks", ">= 1.4.2"
  spec.add_development_dependency "minispec-metadata"
  spec.add_development_dependency "dhash-vips"
end
