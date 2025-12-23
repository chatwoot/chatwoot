# -*- encoding: utf-8 -*-
# stub: dry-core 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-core".freeze
  s.version = "1.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-core/issues", "changelog_uri" => "https://github.com/dry-rb/dry-core/blob/main/CHANGELOG.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/dry-rb/dry-core" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nikita Shilnikov".freeze]
  s.date = "2025-01-04"
  s.description = "A toolset of small support modules used throughout the dry-rb ecosystem".freeze
  s.email = ["fg@flashgordon.ru".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-core".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "A toolset of small support modules used throughout the dry-rb ecosystem".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<logger>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.6".freeze])
end
