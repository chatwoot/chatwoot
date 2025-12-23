# -*- encoding: utf-8 -*-
# stub: vite_rails 3.0.17 ruby lib

Gem::Specification.new do |s|
  s.name = "vite_rails".freeze
  s.version = "3.0.17".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/ElMassimo/vite_ruby/blob/vite_rails@3.0.17/vite_rails/CHANGELOG.md", "source_code_uri" => "https://github.com/ElMassimo/vite_ruby/tree/vite_rails@3.0.17/vite_rails" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["M\u00E1ximo Mussini".freeze]
  s.date = "2023-10-05"
  s.email = ["maximomussini@gmail.com".freeze]
  s.homepage = "https://github.com/ElMassimo/vite_ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Use Vite in Rails and bring joy to your JavaScript experience".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.1".freeze, "< 8".freeze])
  s.add_runtime_dependency(%q<vite_ruby>.freeze, [">= 3.2.2".freeze, "~> 3.0".freeze])
  s.add_development_dependency(%q<spring>.freeze, ["~> 2.1".freeze])
end
