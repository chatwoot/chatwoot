# -*- encoding: utf-8 -*-
# stub: down 5.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "down".freeze
  s.version = "5.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Janko Marohni\u0107".freeze]
  s.date = "2022-12-26"
  s.email = ["janko.marohnic@gmail.com".freeze]
  s.homepage = "https://github.com/janko/down".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Robust streaming downloads using Net::HTTP, HTTP.rb or wget.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.8".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.8".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 1.5".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<httpx>.freeze, ["~> 0.22".freeze, ">= 0.22.2".freeze])
  s.add_development_dependency(%q<http>.freeze, ["~> 5.0".freeze])
  s.add_development_dependency(%q<posix-spawn>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<http_parser.rb>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<warning>.freeze, [">= 0".freeze])
end
