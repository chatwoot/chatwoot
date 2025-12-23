# -*- encoding: utf-8 -*-
# stub: rack-session 2.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-session".freeze
  s.version = "2.1.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Williams".freeze, "Jeremy Evans".freeze, "Jon Dufresne".freeze, "Philip Arndt".freeze]
  s.date = "2025-05-06"
  s.homepage = "https://github.com/rack/rack-session".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.5.22".freeze
  s.summary = "A session implementation for Rack.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<base64>.freeze, [">= 0.1.0".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0".freeze])
  s.add_development_dependency(%q<minitest-global_expectations>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-sprint>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
