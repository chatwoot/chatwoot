# -*- encoding: utf-8 -*-
# stub: aws-sigv4 1.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "aws-sigv4".freeze
  s.version = "1.5.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/aws/aws-sdk-ruby/tree/version-3/gems/aws-sigv4/CHANGELOG.md", "source_code_uri" => "https://github.com/aws/aws-sdk-ruby/tree/version-3/gems/aws-sigv4" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Amazon Web Services".freeze]
  s.date = "2022-09-30"
  s.description = "Amazon Web Services Signature Version 4 signing library. Generates sigv4 signature for HTTP requests.".freeze
  s.homepage = "https://github.com/aws/aws-sdk-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "AWS Signature Version 4 library.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<aws-eventstream>.freeze, ["~> 1".freeze, ">= 1.0.2".freeze])
end
