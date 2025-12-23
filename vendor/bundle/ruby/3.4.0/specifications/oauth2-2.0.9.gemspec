# -*- encoding: utf-8 -*-
# stub: oauth2 2.0.9 ruby lib

Gem::Specification.new do |s|
  s.name = "oauth2".freeze
  s.version = "2.0.9".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://gitlab.com/oauth-xx/oauth2/-/issues", "changelog_uri" => "https://gitlab.com/oauth-xx/oauth2/-/blob/v2.0.9/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/oauth2/2.0.9", "funding_uri" => "https://liberapay.com/pboling", "homepage_uri" => "https://gitlab.com/oauth-xx/oauth2", "rubygems_mfa_required" => "true", "source_code_uri" => "https://gitlab.com/oauth-xx/oauth2/-/tree/v2.0.9", "wiki_uri" => "https://gitlab.com/oauth-xx/oauth2/-/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Peter Boling".freeze, "Erik Michaels-Ober".freeze, "Michael Bleigh".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-09-16"
  s.description = "A Ruby wrapper for the OAuth 2.0 protocol built with a similar style to the original OAuth spec.".freeze
  s.email = ["peter.boling@gmail.com".freeze]
  s.homepage = "https://gitlab.com/oauth-xx/oauth2".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\nYou have installed oauth2 version 2.0.9, congratulations!\n\nThere are BREAKING changes if you are upgrading from < v2, but most will not encounter them, and updating your code should be easy!\n\nWe have made two other major migrations:\n1. master branch renamed to main\n2. Github has been replaced with Gitlab\n\nPlease see:\n\u2022 https://gitlab.com/oauth-xx/oauth2#what-is-new-for-v20\n\u2022 https://gitlab.com/oauth-xx/oauth2/-/blob/main/CHANGELOG.md\n\u2022 https://groups.google.com/g/oauth-ruby/c/QA_dtrXWXaE\n\nPlease report issues, and support the project! Thanks, |7eter l-|. l3oling\n\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "3.3.21".freeze
  s.summary = "A Ruby wrapper for the OAuth 2.0 protocol.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, [">= 0.17.3".freeze, "< 3.0".freeze])
  s.add_runtime_dependency(%q<jwt>.freeze, [">= 1.0".freeze, "< 3.0".freeze])
  s.add_runtime_dependency(%q<multi_xml>.freeze, ["~> 0.5".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 1.2".freeze, "< 4".freeze])
  s.add_runtime_dependency(%q<snaky_hash>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<version_gem>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<addressable>.freeze, [">= 2".freeze])
  s.add_development_dependency(%q<backports>.freeze, [">= 3".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 2".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 12".freeze])
  s.add_development_dependency(%q<rexml>.freeze, [">= 3".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3".freeze])
  s.add_development_dependency(%q<rspec-block_is_expected>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-pending_for>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-stubbed_env>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-lts>.freeze, ["~> 8.0".freeze])
  s.add_development_dependency(%q<silent_stream>.freeze, [">= 0".freeze])
end
