# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/unicode/emoji/constants"

Gem::Specification.new do |gem|
  gem.name          = "unicode-emoji"
  gem.version       = Unicode::Emoji::VERSION
  gem.summary       = "Emoji data and regex"
  gem.description   = "[Emoji #{Unicode::Emoji::EMOJI_VERSION}] Provides Unicode Emoji data and regexes, incorporating the latest Unicode and Emoji standards. Includes a categorized list of recommended Emoji."
  gem.authors       = ["Jan Lelis"]
  gem.email         = ["hi@ruby.consulting"]
  gem.homepage      = "https://github.com/janlelis/unicode-emoji"
  gem.license       = "MIT"

  gem.files         = Dir["{**/}{.*,*}"].select{ |path| File.file?(path) && path !~ /^pkg/ && path !~ /spec\/data\/[^.]/ }
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.metadata      = { "rubygems_mfa_required" => "true" }

  gem.required_ruby_version = ">= 2.5", "< 4.0"
end
