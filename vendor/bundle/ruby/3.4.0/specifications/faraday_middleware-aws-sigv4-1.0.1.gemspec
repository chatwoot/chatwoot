# -*- encoding: utf-8 -*-
# stub: faraday_middleware-aws-sigv4 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "faraday_middleware-aws-sigv4".freeze
  s.version = "1.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Genki Sugawara".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-10-01"
  s.description = "Faraday middleware for AWS Signature Version 4 using aws-sigv4.".freeze
  s.email = ["sugawara@winebarrel.jp".freeze]
  s.homepage = "https://github.com/winebarrel/faraday_middleware-aws-sigv4".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Faraday middleware for AWS Signature Version 4 using aws-sigv4.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<aws-sigv4>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<faraday>.freeze, [">= 2.0".freeze, "< 3".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 2.2".freeze])
  s.add_development_dependency(%q<aws-sdk-core>.freeze, [">= 3.124.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 1.36.0".freeze])
  s.add_development_dependency(%q<rubocop-rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov-lcov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<timecop>.freeze, [">= 0".freeze])
end
