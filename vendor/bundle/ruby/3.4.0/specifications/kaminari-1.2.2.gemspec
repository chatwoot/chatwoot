# -*- encoding: utf-8 -*-
# stub: kaminari 1.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "kaminari".freeze
  s.version = "1.2.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Akira Matsuda".freeze, "Yuki Nishijima".freeze, "Zachary Scott".freeze, "Hiroshi Shibata".freeze]
  s.date = "2021-12-25"
  s.description = "Kaminari is a Scope & Engine based, clean, powerful, agnostic, customizable and sophisticated paginator for Rails 4+".freeze
  s.email = ["ronnie@dio.jp".freeze]
  s.homepage = "https://github.com/kaminari/kaminari".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.3.0.dev".freeze
  s.summary = "A pagination engine plugin for Rails 4+ and other modern frameworks".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.1.0".freeze])
  s.add_runtime_dependency(%q<kaminari-core>.freeze, ["= 1.2.2".freeze])
  s.add_runtime_dependency(%q<kaminari-actionview>.freeze, ["= 1.2.2".freeze])
  s.add_runtime_dependency(%q<kaminari-activerecord>.freeze, ["= 1.2.2".freeze])
  s.add_development_dependency(%q<test-unit-rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.0.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rr>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<capybara>.freeze, [">= 1.0".freeze])
end
