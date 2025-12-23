# encoding: utf-8
# frozen_string_literal: true

require File.expand_path('../lib/parser/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'parser'
  spec.version       = Parser::VERSION
  spec.authors       = ['whitequark']
  spec.email         = ['whitequark@whitequark.org']
  spec.description   = 'A Ruby parser written in pure Ruby.'
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/whitequark/parser'
  spec.license       = 'MIT'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/whitequark/parser/issues',
    'changelog_uri' => "https://github.com/whitequark/parser/blob/v#{spec.version}/CHANGELOG.md",
    'documentation_uri' => "https://www.rubydoc.info/gems/parser/#{spec.version}",
    'source_code_uri' => "https://github.com/whitequark/parser/tree/v#{spec.version}"
  }

  spec.files         = Dir['bin/*', 'lib/**/*.rb', 'parser.gemspec', 'LICENSE.txt']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency             'ast',       '~> 2.4.1'
  spec.add_dependency             'racc'

  spec.add_development_dependency 'bundler',   '>= 1.15', '< 3.0.0'
  spec.add_development_dependency 'rake',      '~> 13.0.1'
  spec.add_development_dependency 'cliver',    '~> 0.3.2'

  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'kramdown'

  spec.add_development_dependency 'minitest',  '~> 5.10'
  spec.add_development_dependency 'simplecov', '~> 0.15.1'

  spec.add_development_dependency 'gauntlet'
end
