# -*- encoding: utf-8 -*-
# stub: letter_opener 1.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "letter_opener".freeze
  s.version = "1.10.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.4".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ryanb/letter_opener/issues", "changelog_uri" => "https://github.com/ryanb/letter_opener/blob/master/CHANGELOG.md", "documentation_uri" => "http://www.rubydoc.info/gems/letter_opener/", "homepage_uri" => "https://github.com/ryanb/letter_opener", "source_code_uri" => "https://github.com/ryanb/letter_opener/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Bates".freeze]
  s.date = "2024-03-30"
  s.description = "When mail is sent from your application, Letter Opener will open a preview in the browser instead of sending.".freeze
  s.email = "ryan@railscasts.com".freeze
  s.homepage = "https://github.com/ryanb/letter_opener".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Preview mail in browser instead of sending.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<launchy>.freeze, [">= 2.2".freeze, "< 4".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10.0".freeze])
  s.add_development_dependency(%q<mail>.freeze, ["~> 2.6.0".freeze])
end
