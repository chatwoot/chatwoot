# -*- encoding: utf-8 -*-
# stub: gapic-common 0.20.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gapic-common".freeze
  s.version = "0.20.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Google API Authors".freeze]
  s.date = "2023-09-05"
  s.email = ["googleapis-packages@google.com".freeze]
  s.homepage = "https://github.com/googleapis/gapic-generator-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Common code for GAPIC-generated API clients".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, [">= 1.9".freeze, "< 3.a".freeze])
  s.add_runtime_dependency(%q<faraday-retry>.freeze, [">= 1.0".freeze, "< 3.a".freeze])
  s.add_runtime_dependency(%q<googleapis-common-protos>.freeze, [">= 1.3.12".freeze, "< 2.a".freeze])
  s.add_runtime_dependency(%q<googleapis-common-protos-types>.freeze, [">= 1.3.1".freeze, "< 2.a".freeze])
  s.add_runtime_dependency(%q<googleauth>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<google-protobuf>.freeze, ["~> 3.14".freeze])
  s.add_runtime_dependency(%q<grpc>.freeze, ["~> 1.36".freeze])
  s.add_development_dependency(%q<concurrent-ruby>.freeze, ["~> 1.2.2".freeze])
  s.add_development_dependency(%q<google-cloud-core>.freeze, ["~> 1.5".freeze])
  s.add_development_dependency(%q<google-style>.freeze, ["~> 1.26.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.16".freeze])
  s.add_development_dependency(%q<minitest-autotest>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<minitest-focus>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<minitest-rg>.freeze, ["~> 5.2".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0.14".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.0".freeze])
  s.add_development_dependency(%q<redcarpet>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9".freeze])
end
