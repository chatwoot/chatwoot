# -*- encoding: utf-8 -*-
# stub: webmock 3.23.1 ruby lib

Gem::Specification.new do |s|
  s.name = "webmock".freeze
  s.version = "3.23.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/bblimke/webmock/issues", "changelog_uri" => "https://github.com/bblimke/webmock/blob/v3.23.1/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/webmock/3.23.1", "source_code_uri" => "https://github.com/bblimke/webmock/tree/v3.23.1", "wiki_uri" => "https://github.com/bblimke/webmock/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bartosz Blimke".freeze]
  s.date = "2024-05-24"
  s.description = "WebMock allows stubbing HTTP requests and setting expectations on HTTP requests.".freeze
  s.email = ["bartosz.blimke@gmail.com".freeze]
  s.homepage = "https://github.com/bblimke/webmock".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.5.7".freeze
  s.summary = "Library for stubbing HTTP requests in Ruby.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<addressable>.freeze, [">= 2.8.0".freeze])
  s.add_runtime_dependency(%q<crack>.freeze, [">= 0.3.2".freeze])
  s.add_runtime_dependency(%q<hashdiff>.freeze, [">= 0.4.0".freeze, "< 2.0.0".freeze])
  s.add_development_dependency(%q<patron>.freeze, [">= 0.4.18".freeze])
  s.add_development_dependency(%q<curb>.freeze, [">= 0.7.16".freeze])
  s.add_development_dependency(%q<typhoeus>.freeze, [">= 0.5.0".freeze])
  s.add_development_dependency(%q<em-http-request>.freeze, [">= 1.0.2".freeze])
  s.add_development_dependency(%q<em-synchrony>.freeze, [">= 1.0.0".freeze])
  s.add_development_dependency(%q<async-http>.freeze, [">= 0.48.0".freeze])
  s.add_development_dependency(%q<http>.freeze, [">= 0.8.0".freeze])
  s.add_development_dependency(%q<rack>.freeze, ["> 1.6".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.1.0".freeze])
  s.add_development_dependency(%q<httpclient>.freeze, [">= 2.2.4".freeze])
  s.add_development_dependency(%q<mutex_m>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<excon>.freeze, [">= 0.27.5".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 5.0.0".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, ["> 3.5.0".freeze])
  s.add_development_dependency(%q<webrick>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-retry>.freeze, [">= 0".freeze])
end
