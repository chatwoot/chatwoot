# -*- encoding: utf-8 -*-
# stub: opentelemetry-registry 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "opentelemetry-registry".freeze
  s.version = "0.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/open-telemetry/opentelemetry-ruby/issues", "changelog_uri" => "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-instrumentation-registry/v0.4.0/file.CHANGELOG.html", "documentation_uri" => "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-instrumentation-registry/v0.4.0", "source_code_uri" => "https://github.com/open-telemetry/opentelemetry-ruby/tree/main/instrumentation/registry" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["OpenTelemetry Authors".freeze]
  s.date = "2025-02-25"
  s.description = "Registry for the OpenTelemetry Instrumentation Libraries".freeze
  s.email = ["cncf-opentelemetry-contributors@lists.cncf.io".freeze]
  s.homepage = "https://github.com/open-telemetry/opentelemetry-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "Registry for the OpenTelemetry Instrumentation Libraries".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<opentelemetry-api>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.2.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.17".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3.3".freeze])
  s.add_development_dependency(%q<rspec-mocks>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.65".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.17.1".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9".freeze])
  s.add_development_dependency(%q<yard-doctest>.freeze, ["~> 0.1.6".freeze])
end
