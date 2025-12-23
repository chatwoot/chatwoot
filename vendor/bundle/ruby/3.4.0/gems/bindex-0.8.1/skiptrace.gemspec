$LOAD_PATH << File.expand_path('../lib', __FILE__)

require 'skiptrace/version'

Gem::Specification.new do |spec|
  spec.name          = "skiptrace"
  spec.version       = Skiptrace::VERSION
  spec.authors       = ["Genadi Samokovarov"]
  spec.email         = ["gsamokovarov@gmail.com"]
  spec.extensions    = ["ext/skiptrace/extconf.rb"]
  spec.summary       = "Bindings for your Ruby exceptions"
  spec.homepage      = "https://github.com/gsamokovarov/skiptrace"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.5.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/skiptrace/extconf.rb"]

  spec.add_development_dependency "minitest", "~> 5.4"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rake-compiler"
end
