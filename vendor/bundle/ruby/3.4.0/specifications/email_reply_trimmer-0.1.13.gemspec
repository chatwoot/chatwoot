# -*- encoding: utf-8 -*-
# stub: email_reply_trimmer 0.1.13 ruby lib

Gem::Specification.new do |s|
  s.name = "email_reply_trimmer".freeze
  s.version = "0.1.13".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["R\u00E9gis Hanol".freeze]
  s.date = "2020-06-04"
  s.description = "EmailReplyTrimmer is a small library to trim replies from plain text email.".freeze
  s.email = ["regis+rubygems@hanol.fr".freeze]
  s.homepage = "https://github.com/discourse/email_reply_trimmer".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Library to trim replies from plain text email.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 12".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.52.1".freeze])
end
