# -*- encoding: utf-8 -*-
# stub: faraday-multipart 1.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "faraday-multipart".freeze
  s.version = "1.0.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/lostisland/faraday-multipart/issues", "changelog_uri" => "https://github.com/lostisland/faraday-multipart/blob/v1.0.4/CHANGELOG.md", "documentation_uri" => "http://www.rubydoc.info/gems/faraday-multipart/1.0.4", "homepage_uri" => "https://github.com/lostisland/faraday-multipart", "source_code_uri" => "https://github.com/lostisland/faraday-multipart", "wiki_uri" => "https://github.com/lostisland/faraday-multipart/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mattia Giuffrida".freeze]
  s.date = "2022-06-07"
  s.description = "Perform multipart-post requests using Faraday.\n".freeze
  s.email = ["giuffrida.mattia@gmail.com".freeze]
  s.homepage = "https://github.com/lostisland/faraday-multipart".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.4".freeze, "< 4".freeze])
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Perform multipart-post requests using Faraday.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<multipart-post>.freeze, ["~> 2".freeze])
end
