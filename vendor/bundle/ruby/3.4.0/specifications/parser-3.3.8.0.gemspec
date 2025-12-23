# -*- encoding: utf-8 -*-
# stub: parser 3.3.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "parser".freeze
  s.version = "3.3.8.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/whitequark/parser/issues", "changelog_uri" => "https://github.com/whitequark/parser/blob/v3.3.8.0/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/parser/3.3.8.0", "source_code_uri" => "https://github.com/whitequark/parser/tree/v3.3.8.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["whitequark".freeze]
  s.date = "2025-04-14"
  s.description = "A Ruby parser written in pure Ruby.".freeze
  s.email = ["whitequark@whitequark.org".freeze]
  s.executables = ["ruby-parse".freeze, "ruby-rewrite".freeze]
  s.files = ["bin/ruby-parse".freeze, "bin/ruby-rewrite".freeze]
  s.homepage = "https://github.com/whitequark/parser".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "A Ruby parser written in pure Ruby.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<ast>.freeze, ["~> 2.4.1".freeze])
  s.add_runtime_dependency(%q<racc>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.15".freeze, "< 3.0.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0.1".freeze])
  s.add_development_dependency(%q<cliver>.freeze, ["~> 0.3.2".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<kramdown>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.10".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.15.1".freeze])
  s.add_development_dependency(%q<gauntlet>.freeze, [">= 0".freeze])
end
