# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'working_hours/version'

Gem::Specification.new do |spec|
  spec.name          = "working_hours"
  spec.version       = WorkingHours::VERSION
  spec.authors       = ["Adrien Jarthon", "Intrepidd"]
  spec.email         = ["me@adrienjarthon.com", "adrien@siami.fr"]
  spec.summary       = %q{time calculation with working hours}
  spec.description   = %q{A modern ruby gem allowing to do time calculation with working hours.}
  spec.homepage      = "https://github.com/intrepidd/working_hours"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport', '>= 3.2'
  spec.add_dependency 'tzinfo'

  spec.add_development_dependency 'bundler', '>= 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'timecop'
end
