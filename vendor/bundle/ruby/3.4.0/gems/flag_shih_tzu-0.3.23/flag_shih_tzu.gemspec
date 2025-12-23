# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flag_shih_tzu/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "flag_shih_tzu"
  gem.version     = FlagShihTzu::VERSION
  gem.licenses    = ['MIT']
  gem.email       = 'peter.boling@gmail.com'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ["Peter Boling", "Patryk Peszko", "Sebastian Roebke", "David Anderson", "Tim Payton"]
  gem.homepage    = "https://github.com/pboling/flag_shih_tzu"
  gem.summary     = %q{Bit fields for ActiveRecord}
  gem.description = <<-EODOC
Bit fields for ActiveRecord:
This gem lets you use a single integer column in an ActiveRecord model
to store a collection of boolean attributes (flags). Each flag can be used
almost in the same way you would use any boolean attribute on an
ActiveRecord object.
  EODOC

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_development_dependency('activerecord', '>= 2.3.0')

  gem.add_development_dependency('bundler', '~> 1')
  gem.add_development_dependency('rake', '>= 0.9')
  gem.add_development_dependency('rdoc', '~> 5.1') # v6 requires Ruby 2.2+
  gem.add_development_dependency('test-unit', '~> 3')
  gem.add_development_dependency('wwtd', '~> 1')
  # latest gem-release does not support back to the versions of Ruby still supported here
  # gem.add_development_dependency('gem-release', '~> 2')
end
