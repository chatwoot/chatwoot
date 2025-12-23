# -*- encoding: utf-8 -*-
# stub: opentelemetry-api 1.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "opentelemetry-api".freeze
  s.version = "1.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/open-telemetry/opentelemetry-ruby/issues", "changelog_uri" => "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-api/v1.7.0/file.CHANGELOG.html", "documentation_uri" => "https://open-telemetry.github.io/opentelemetry-ruby/opentelemetry-api/v1.7.0", "source_code_uri" => "https://github.com/open-telemetry/opentelemetry-ruby/tree/main/api" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["OpenTelemetry Authors".freeze]
  s.date = "2025-09-17"
  s.description = "A stats collection and distributed tracing framework".freeze
  s.email = ["cncf-opentelemetry-contributors@lists.cncf.io".freeze]
  s.homepage = "https://github.com/open-telemetry/opentelemetry-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "A stats collection and distributed tracing framework".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<benchmark-ipsa>.freeze, ["~> 0.2.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.17".freeze])
  s.add_development_dependency(%q<concurrent-ruby>.freeze, ["~> 1.3".freeze])
  s.add_development_dependency(%q<faraday>.freeze, ["~> 0.13".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0".freeze])
  s.add_development_dependency(%q<opentelemetry-test-helpers>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.65".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.17".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9".freeze])
  s.add_development_dependency(%q<yard-doctest>.freeze, ["~> 0.1.6".freeze])
end
