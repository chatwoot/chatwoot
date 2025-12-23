lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'representable/version'

Gem::Specification.new do |spec|
  spec.name        = "representable"
  spec.version     = Representable::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ["Nick Sutterer"]
  spec.email       = ["apotonick@gmail.com"]
  spec.homepage    = "https://github.com/trailblazer/representable/"
  spec.summary     = %q{Renders and parses JSON/XML/YAML documents from and to Ruby objects. Includes plain properties, collections, nesting, coercion and more.}
  spec.description = spec.summary

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2.4.0'

  spec.add_dependency "uber",               "< 0.2.0"
  spec.add_dependency "declarative",        "< 0.1.0"
  spec.add_dependency "trailblazer-option", ">= 0.1.1", "< 0.2.0"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "test_xml", ">= 0.1.6"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "virtus"
  spec.add_development_dependency "dry-types"
  spec.add_development_dependency "ruby-prof" if RUBY_ENGINE == "ruby" # mri
end
