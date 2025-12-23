# -*- encoding: utf-8 -*-
# stub: mail 2.8.1 ruby lib

Gem::Specification.new do |s|
  s.name = "mail".freeze
  s.version = "2.8.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mikel Lindsaar".freeze]
  s.date = "2023-02-03"
  s.description = "A really Ruby Mail handler.".freeze
  s.email = "raasdnil@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/mikel/mail".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--exclude".freeze, "lib/mail/values/unicode_tables.dat".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Mail provides a nice Ruby DSL for making, sending and reading emails.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<mini_mime>.freeze, [">= 0.1.1".freeze])
  s.add_runtime_dependency(%q<net-smtp>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<net-imap>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<net-pop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.0.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["> 0.8.7".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rspec-benchmark>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rufo>.freeze, [">= 0".freeze])
end
