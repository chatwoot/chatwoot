# -*- encoding: utf-8 -*-
# stub: oauth 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "oauth".freeze
  s.version = "1.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/oauth-xx/oauth-ruby/issues", "changelog_uri" => "https://github.com/oauth-xx/oauth-ruby/blob/v1.1.0/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/oauth/1.1.0", "homepage_uri" => "https://github.com/oauth-xx/oauth-ruby", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/oauth-xx/oauth-ruby/tree/v1.1.0", "wiki_uri" => "https://github.com/oauth-xx/oauth-ruby/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pelle Braendgaard".freeze, "Blaine Cook".freeze, "Larry Halff".freeze, "Jesse Clark".freeze, "Jon Crosby".freeze, "Seth Fitzsimmons".freeze, "Matt Sanford".freeze, "Aaron Quint".freeze, "Peter Boling".freeze]
  s.date = "2022-08-29"
  s.email = "oauth-ruby@googlegroups.com".freeze
  s.extra_rdoc_files = ["TODO".freeze]
  s.files = ["TODO".freeze]
  s.homepage = "https://github.com/oauth-xx/oauth-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\nYou have installed oauth version 1.1.0, congratulations!\n\nNon-commercial support for the 1.x series will end by April, 2025. Please make a plan to upgrade to the next version prior to that date.\nThe only breaking change will be dropped support for Ruby 2.7 and any other versions which will also have reached EOL by then.\n\nPlease see:\n\u2022 https://github.com/oauth-xx/oauth-ruby/blob/main/SECURITY.md\n\nNote also that I am, and this project is, in the process of leaving Github.\nI wrote about some of the reasons here:\n\u2022 https://dev.to/galtzo/im-leaving-github-50ba\n\nIf you are a human, please consider a donation as I move toward supporting myself with Open Source work:\n\u2022 https://liberapay.com/pboling\n\u2022 https://ko-fi.com/pboling\n\u2022 https://patreon.com/galtzo\n\nIf you are a corporation, please consider supporting this project, and open source work generally, with a TideLift subscription.\n\u2022 https://tidelift.com/funding/github/rubygems/oauth\n\u2022 Or hire me. I am looking for a job!\n\nPlease report issues, and support the project!\n\nThanks, |7eter l-|. l3oling\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.3.21".freeze
  s.summary = "OAuth Core Ruby implementation".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<oauth-tty>.freeze, ["~> 1.0".freeze, ">= 1.0.1".freeze])
  s.add_runtime_dependency(%q<snaky_hash>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<version_gem>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<em-http-request>.freeze, ["~> 1.1.7".freeze])
  s.add_development_dependency(%q<iconv>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.15.0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rest-client>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-lts>.freeze, ["~> 18.0".freeze])
  s.add_development_dependency(%q<typhoeus>.freeze, [">= 0.1.13".freeze])
  s.add_development_dependency(%q<webmock>.freeze, ["<= 3.19.0".freeze])
end
