# -*- encoding: utf-8 -*-
# stub: active_record_query_trace 1.8 ruby lib

Gem::Specification.new do |s|
  s.name = "active_record_query_trace".freeze
  s.version = "1.8".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Cody Caughlan".freeze, "Bruno Facca".freeze]
  s.date = "2020-10-13"
  s.description = "Print stack trace of all DB queries to the Rails log. Helpful to find where queries are being executed in your application.".freeze
  s.email = "bruno@facca.info".freeze
  s.homepage = "https://github.com/brunofacca/active-record-query-trace".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.4".freeze, "< 4.0".freeze])
  s.rubygems_version = "3.0.6".freeze
  s.summary = "Print stack trace of all DB queries to the Rails log. Helpful to find where queries are being executed in your application.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<activerecord>.freeze, [">= 4.0.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.13.0".freeze])
  s.add_development_dependency(%q<pry-byebug>.freeze, ["~> 3.9.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.8.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0.65.0".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 1.32.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0.16.1".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 1.3.6".freeze])
end
