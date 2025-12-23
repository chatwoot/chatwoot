# -*- encoding: utf-8 -*-
# stub: rest-client 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rest-client".freeze
  s.version = "2.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["REST Client Team".freeze]
  s.date = "2019-08-21"
  s.description = "A simple HTTP and REST client for Ruby, inspired by the Sinatra microframework style of specifying actions: get, put, post, delete.".freeze
  s.email = "discuss@rest-client.groups.io".freeze
  s.executables = ["restclient".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "history.md".freeze]
  s.files = ["README.md".freeze, "bin/restclient".freeze, "history.md".freeze]
  s.homepage = "https://github.com/rest-client/rest-client".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Simple HTTP and REST client for Ruby, inspired by microframework syntax for specifying actions.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<webmock>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0".freeze])
  s.add_development_dependency(%q<pry-doc>.freeze, ["~> 0".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 2.4.2".freeze, "< 6.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.49".freeze])
  s.add_runtime_dependency(%q<http-accept>.freeze, [">= 1.7.0".freeze, "< 2.0".freeze])
  s.add_runtime_dependency(%q<http-cookie>.freeze, [">= 1.0.2".freeze, "< 2.0".freeze])
  s.add_runtime_dependency(%q<mime-types>.freeze, [">= 1.16".freeze, "< 4.0".freeze])
  s.add_runtime_dependency(%q<netrc>.freeze, ["~> 0.8".freeze])
end
