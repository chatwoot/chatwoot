lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unf_ext/version'

Gem::Specification.new do |gem|
  gem.name          = "unf_ext"
  gem.version       = UNF::Normalizer::VERSION
  gem.authors       = ["Takeru Ohta", "Akinori MUSHA"]
  gem.email         = ["knu@idaemons.org"]
  gem.description   = %q{Unicode Normalization Form support library for CRuby}
  gem.summary       = %q{Unicode Normalization Form support library for CRuby}
  gem.homepage      = "https://github.com/knu/ruby-unf_ext"
  gem.licenses      = ["MIT"]

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/}).grep(%r{/test_[^/]+\.rb$})
  gem.require_paths = ["lib"]
  gem.extensions    = ["ext/unf_ext/extconf.rb"]

  gem.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]

  gem.required_ruby_version = '>= 2.2'

  gem.add_development_dependency("rake", [">= 0.9.2.2"])
  gem.add_development_dependency("test-unit")
  gem.add_development_dependency("rdoc", ["> 2.4.2"])
  gem.add_development_dependency("bundler", [">= 1.2"])
  gem.add_development_dependency("rake-compiler", [">= 1.1.1"])
  gem.add_development_dependency("rake-compiler-dock", [">= 1.2.1"])
end
