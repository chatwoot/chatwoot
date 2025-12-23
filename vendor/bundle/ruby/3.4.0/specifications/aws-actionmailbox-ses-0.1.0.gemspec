# -*- encoding: utf-8 -*-
# stub: aws-actionmailbox-ses 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "aws-actionmailbox-ses".freeze
  s.version = "0.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Amazon Web Services".freeze]
  s.date = "2024-11-16"
  s.description = "Amazon Simple Email Service as an ActionMailbox router".freeze
  s.email = ["aws-dr-rubygems@amazon.com".freeze]
  s.homepage = "https://github.com/aws/aws-actionmailbox-ses-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.5.11".freeze
  s.summary = "ActionMailbox integration with SES".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<aws-sdk-s3>.freeze, ["~> 1".freeze, ">= 1.123.0".freeze])
  s.add_runtime_dependency(%q<aws-sdk-sns>.freeze, ["~> 1".freeze, ">= 1.61.0".freeze])
  s.add_runtime_dependency(%q<actionmailbox>.freeze, [">= 7.1.0".freeze])
end
