# -*- encoding: utf-8 -*-
# stub: google-cloud-env 2.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "google-cloud-env".freeze
  s.version = "2.2.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/googleapis/ruby-cloud-env/issues", "changelog_uri" => "https://rubydoc.info/gems/google-cloud-env/2.2.1/CHANGELOG.md", "documentation_uri" => "https://rubydoc.info/gems/google-cloud-env/2.2.1", "source_code_uri" => "https://github.com/googleapis/ruby-cloud-env" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Azuma".freeze]
  s.date = "2024-10-04"
  s.description = "google-cloud-env provides information on the Google Cloud Platform hosting environment. Applications can use this library to determine hosting context information such as the project ID, whether App Engine is running, what tags are set on the VM instance, and much more.".freeze
  s.email = ["dazuma@google.com".freeze]
  s.homepage = "https://github.com/googleapis/ruby-cloud-env".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "3.5.6".freeze
  s.summary = "Google Cloud Platform hosting environment information.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, [">= 1.0".freeze, "< 3.a".freeze])
end
