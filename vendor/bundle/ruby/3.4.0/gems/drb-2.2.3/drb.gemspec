begin
  require_relative "lib/drb/version"
rescue LoadError # Fallback to load version file in ruby core repository
  require_relative "version"
end

Gem::Specification.new do |spec|
  spec.name          = "drb"
  spec.version       = DRb::VERSION
  spec.authors       = ["Masatoshi SEKI"]
  spec.email         = ["seki@ruby-lang.org"]

  spec.summary       = %q{Distributed object system for Ruby}
  spec.description   = %q{Distributed object system for Ruby}
  spec.homepage      = "https://github.com/ruby/drb"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")
  spec.licenses      = ["Ruby", "BSD-2-Clause"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] =
    "#{spec.homepage}/releases/tag/v#{spec.version}"

  spec.files         = %w[
    LICENSE.txt
    drb.gemspec
    lib/drb.rb
    lib/drb/acl.rb
    lib/drb/drb.rb
    lib/drb/eq.rb
    lib/drb/extserv.rb
    lib/drb/extservm.rb
    lib/drb/gw.rb
    lib/drb/observer.rb
    lib/drb/ssl.rb
    lib/drb/timeridconv.rb
    lib/drb/unix.rb
    lib/drb/version.rb
    lib/drb/weakidconv.rb
  ]
  spec.require_paths = ["lib"]
end
