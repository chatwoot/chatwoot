# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bundle/audit/version"

Gem::Specification.new do |spec|
  spec.name          = "bundle-audit"
  spec.version       = Bundle::Audit::VERSION
  spec.authors       = ["Stewart McKee"]
  spec.email         = ["stewart@theizone.co.uk"]

  spec.summary       = "Helper gem to require bundler-audit"
  spec.description   = "Just requires bundler-audit, if you've mistakenly required bundle-audit"
  spec.homepage      = "http://github.com/stewartmckee/bundle-audit"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler-audit"

  spec.add_development_dependency "bundler", "~> 1.15"
end
