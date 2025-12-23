lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "trailblazer/option/version"

Gem::Specification.new do |spec|
  spec.name          = "trailblazer-option"
  spec.version       = Trailblazer::Option::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]

  spec.summary       = "Callable patterns for options in Trailblazer"
  spec.description   = "Wrap an option at compile-time and `call` it at runtime, which allows to have the common `-> ()`, `:method` or `Callable` pattern used for most options."
  spec.homepage      = "https://trailblazer.to/"
  spec.licenses      = ["MIT"]

  spec.files         = `git ls-files -z`.split("\x0").reject do |f| 
    f.match(%r(^test/))
  end 
  spec.test_files    = `git ls-files -z test`.split("\x0")

  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-line", "~> 0.6.5"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.required_ruby_version = ">= 2.1.0"
end
