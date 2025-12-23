# -*- encoding: utf-8 -*-
# stub: listen 3.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "listen".freeze
  s.version = "3.8.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/guard/listen/issues", "changelog_uri" => "https://github.com/guard/listen/releases", "documentation_uri" => "https://www.rubydoc.info/gems/listen/3.8.0", "homepage_uri" => "https://github.com/guard/listen", "source_code_uri" => "https://github.com/guard/listen/tree/v3.8.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thibaud Guillaume-Gentil".freeze]
  s.date = "2023-01-09"
  s.description = "The Listen gem listens to file modifications and notifies you about the changes. Works everywhere!".freeze
  s.email = "thibaud@thibaud.gg".freeze
  s.executables = ["listen".freeze]
  s.files = ["bin/listen".freeze]
  s.homepage = "https://github.com/guard/listen".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.0.1".freeze
  s.summary = "Listen to file modifications".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rb-fsevent>.freeze, ["~> 0.10".freeze, ">= 0.10.3".freeze])
  s.add_runtime_dependency(%q<rb-inotify>.freeze, ["~> 0.9".freeze, ">= 0.9.10".freeze])
end
