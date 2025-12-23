# -*- encoding: utf-8 -*-
# stub: omniauth-rails_csrf_protection 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-rails_csrf_protection".freeze
  s.version = "1.0.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Cookpad Inc.".freeze]
  s.date = "2024-05-10"
  s.description = "This gem provides a mitigation against CVE-2015-9284 (Cross-Site Request\nForgery on the request phrase when using OmniAuth gem with a Ruby on Rails\napplication) by implementing a CSRF token verifier that directly utilize\n`ActionController::RequestForgeryProtection` code from Rails.\n".freeze
  s.email = ["kaihatsu@cookpad.com".freeze]
  s.homepage = "https://github.com/cookpad/omniauth-rails_csrf_protection".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Provides CSRF protection on OmniAuth request endpoint on Rails application.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 4.2".freeze])
  s.add_runtime_dependency(%q<omniauth>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
