# -*- encoding: utf-8 -*-
# stub: newrelic-sidekiq-metrics 1.6.2 ruby lib

Gem::Specification.new do |s|
  s.name = "newrelic-sidekiq-metrics".freeze
  s.version = "1.6.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/RenoFi/newrelic-sidekiq-metrics", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/RenoFi/newrelic-sidekiq-metrics" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Krzysztof Knapik".freeze, "RenoFi Engineering Team".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-10-30"
  s.email = ["knapo@knapo.net".freeze, "engineering@renofi.com".freeze]
  s.homepage = "https://github.com/RenoFi/newrelic-sidekiq-metrics".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.21".freeze
  s.summary = "Implements recording Sidekiq stats to New Relic metrics.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<newrelic_rpm>.freeze, [">= 8.0.0".freeze])
  s.add_runtime_dependency(%q<sidekiq>.freeze, [">= 0".freeze])
end
