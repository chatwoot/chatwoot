# -*- encoding: utf-8 -*-
# stub: uniform_notifier 1.17.0 ruby lib

Gem::Specification.new do |s|
  s.name = "uniform_notifier".freeze
  s.version = "1.17.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/flyerhzm/uniform_notifier/issues", "changelog_uri" => "https://github.com/flyerhzm/uniform_notifier/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/flyerhzm/uniform_notifier" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Richard Huang".freeze]
  s.date = "1980-01-02"
  s.description = "uniform notifier for rails logger, customized logger, javascript alert, javascript console and xmpp".freeze
  s.email = ["flyerhzm@gmail.com".freeze]
  s.homepage = "http://rubygems.org/gems/uniform_notifier".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.6.7".freeze
  s.summary = "uniform notifier for rails logger, customized logger, javascript alert, javascript console and xmpp".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, ["> 0".freeze])
  s.add_development_dependency(%q<slack-notifier>.freeze, [">= 1.0".freeze])
  s.add_development_dependency(%q<xmpp4r>.freeze, ["= 0.5".freeze])
end
