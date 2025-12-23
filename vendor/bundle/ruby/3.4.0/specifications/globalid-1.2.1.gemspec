# -*- encoding: utf-8 -*-
# stub: globalid 1.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "globalid".freeze
  s.version = "1.2.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2023-09-05"
  s.description = "URIs for your models makes it easy to pass references around.".freeze
  s.email = "david@loudthinking.com".freeze
  s.homepage = "http://www.rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Refer to any model with a URI: gid://app/class/id".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 6.1".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
