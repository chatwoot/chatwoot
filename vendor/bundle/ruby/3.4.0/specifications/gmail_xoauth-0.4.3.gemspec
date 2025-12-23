# -*- encoding: utf-8 -*-
# stub: gmail_xoauth 0.4.3 ruby lib

Gem::Specification.new do |s|
  s.name = "gmail_xoauth".freeze
  s.version = "0.4.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nicolas Fouch\u00E9".freeze]
  s.date = "2024-01-17"
  s.description = "Get access to Gmail IMAP and STMP via OAuth, using the standard Ruby Net libraries".freeze
  s.email = ["nicolas.fouche@gmail.com".freeze]
  s.homepage = "https://github.com/nfo/gmail_xoauth".freeze
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Get access to Gmail IMAP and STMP via OAuth, using the standard Ruby Net libraries".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<oauth>.freeze, [">= 0.3.6".freeze])
  s.add_development_dependency(%q<shoulda>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0".freeze])
end
