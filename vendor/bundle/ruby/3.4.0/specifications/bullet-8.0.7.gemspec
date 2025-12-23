# -*- encoding: utf-8 -*-
# stub: bullet 8.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "bullet".freeze
  s.version = "8.0.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/flyerhzm/bullet/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/flyerhzm/bullet" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Richard Huang".freeze]
  s.date = "1980-01-02"
  s.description = "help to kill N+1 queries and unused eager loading.".freeze
  s.email = ["flyerhzm@gmail.com".freeze]
  s.homepage = "https://github.com/flyerhzm/bullet".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.6.7".freeze
  s.summary = "help to kill N+1 queries and unused eager loading.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.0.0".freeze])
  s.add_runtime_dependency(%q<uniform_notifier>.freeze, ["~> 1.11".freeze])
end
