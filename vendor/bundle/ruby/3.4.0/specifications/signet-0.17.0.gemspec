# -*- encoding: utf-8 -*-
# stub: signet 0.17.0 ruby lib

Gem::Specification.new do |s|
  s.name = "signet".freeze
  s.version = "0.17.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/googleapis/signet/issues", "changelog_uri" => "https://github.com/googleapis/signet/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/googleapis/signet" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bob Aman".freeze, "Steven Bazyl".freeze]
  s.date = "2022-06-23"
  s.description = "Signet is an OAuth 1.0 / OAuth 2.0 implementation.\n".freeze
  s.email = "sbazyl@google.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/googleapis/signet".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.3.14".freeze
  s.summary = "Signet is an OAuth 1.0 / OAuth 2.0 implementation.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.8".freeze])
  s.add_runtime_dependency(%q<faraday>.freeze, [">= 0.17.5".freeze, "< 3.a".freeze])
  s.add_runtime_dependency(%q<jwt>.freeze, [">= 1.5".freeze, "< 3.0".freeze])
  s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.10".freeze])
  s.add_development_dependency(%q<google-style>.freeze, ["~> 1.26.0".freeze])
  s.add_development_dependency(%q<kramdown>.freeze, ["~> 1.5".freeze])
  s.add_development_dependency(%q<launchy>.freeze, ["~> 2.4".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<redcarpet>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.1".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9".freeze, ">= 0.9.12".freeze])
end
