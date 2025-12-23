# -*- encoding: utf-8 -*-
# stub: oj 3.16.10 ruby lib
# stub: ext/oj/extconf.rb

Gem::Specification.new do |s|
  s.name = "oj".freeze
  s.version = "3.16.10".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ohler55/oj/issues", "changelog_uri" => "https://github.com/ohler55/oj/blob/master/CHANGELOG.md", "documentation_uri" => "http://www.ohler.com/oj/doc/index.html", "homepage_uri" => "http://www.ohler.com/oj/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/ohler55/oj", "wiki_uri" => "https://github.com/ohler55/oj/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Peter Ohler".freeze]
  s.date = "2025-02-25"
  s.description = "The fastest JSON parser and object serializer.".freeze
  s.email = "peter@ohler.com".freeze
  s.extensions = ["ext/oj/extconf.rb".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "LICENSE".freeze, "CHANGELOG.md".freeze, "RELEASE_NOTES.md".freeze, "pages/Advanced.md".freeze, "pages/Compatibility.md".freeze, "pages/Custom.md".freeze, "pages/Encoding.md".freeze, "pages/InstallOptions.md".freeze, "pages/JsonGem.md".freeze, "pages/Modes.md".freeze, "pages/Options.md".freeze, "pages/Parser.md".freeze, "pages/Rails.md".freeze, "pages/Security.md".freeze, "pages/WAB.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE".freeze, "README.md".freeze, "RELEASE_NOTES.md".freeze, "ext/oj/extconf.rb".freeze, "pages/Advanced.md".freeze, "pages/Compatibility.md".freeze, "pages/Custom.md".freeze, "pages/Encoding.md".freeze, "pages/InstallOptions.md".freeze, "pages/JsonGem.md".freeze, "pages/Modes.md".freeze, "pages/Options.md".freeze, "pages/Parser.md".freeze, "pages/Rails.md".freeze, "pages/Security.md".freeze, "pages/WAB.md".freeze]
  s.homepage = "http://www.ohler.com/oj".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--title".freeze, "Oj".freeze, "--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "A fast JSON parser and serializer.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 3.0".freeze])
  s.add_runtime_dependency(%q<ostruct>.freeze, [">= 0.2".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5".freeze])
  s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0.9".freeze, "< 2.0".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.0".freeze])
end
