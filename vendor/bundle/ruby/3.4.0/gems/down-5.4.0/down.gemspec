require File.expand_path("../lib/down/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name         = "down"
  spec.version      = Down::VERSION

  spec.required_ruby_version = ">= 2.3"

  spec.summary      = "Robust streaming downloads using Net::HTTP, HTTP.rb or wget."
  spec.homepage     = "https://github.com/janko/down"
  spec.authors      = ["Janko Marohnić"]
  spec.email        = ["janko.marohnic@gmail.com"]
  spec.license      = "MIT"

  spec.files        = Dir["README.md", "LICENSE.txt", "CHANGELOG.md", "*.gemspec", "lib/**/*.rb"]
  spec.require_path = "lib"

  spec.add_dependency "addressable", "~> 2.8"

  spec.add_development_dependency "minitest", "~> 5.8"
  spec.add_development_dependency "mocha", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "httpx", "~> 0.22", ">= 0.22.2"
  # http 5.0 drop support of ruby 2.3 and 2.4. We still support those versions.
  if RUBY_VERSION >= "2.5"
    spec.add_development_dependency "http", "~> 5.0"
  else
    spec.add_development_dependency "http", "~> 4.3"
  end
  spec.add_development_dependency "posix-spawn" unless RUBY_ENGINE == "jruby"
  spec.add_development_dependency "http_parser.rb" unless RUBY_ENGINE == "jruby"
  spec.add_development_dependency "warning" if RUBY_VERSION >= "2.4"
end
