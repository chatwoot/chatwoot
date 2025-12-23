$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'regexp_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'regexp_parser'
  spec.version       = ::Regexp::Parser::VERSION

  spec.summary       = "Scanner, lexer, parser for ruby's regular expressions"
  spec.description   = 'A library for tokenizing, lexing, and parsing Ruby regular expressions.'
  spec.homepage      = 'https://github.com/ammar/regexp_parser'

  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['wiki_uri']        = "#{spec.homepage}/wiki"

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.authors       = ['Ammar Ali', 'Janosch Müller']
  spec.email         = ['ammarabuali@gmail.com', 'janosch84@gmail.com']

  spec.license       = 'MIT'

  spec.require_paths = ['lib']

  spec.files         = Dir.glob('lib/**/*.{csv,rb,rl}') +
                       %w[Gemfile Rakefile LICENSE regexp_parser.gemspec]

  spec.platform      = Gem::Platform::RUBY

  spec.required_ruby_version = '>= 2.0.0'
end
