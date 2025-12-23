# -*- encoding: utf-8 -*-
# stub: llhttp-ffi 0.4.0 ruby lib
# stub: ext/Rakefile

Gem::Specification.new do |s|
  s.name = "llhttp-ffi".freeze
  s.version = "0.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bryan Powell".freeze]
  s.date = "2021-09-09"
  s.description = "Ruby FFI bindings for llhttp.".freeze
  s.email = "bryan@metabahn.com".freeze
  s.extensions = ["ext/Rakefile".freeze]
  s.files = ["ext/Rakefile".freeze]
  s.homepage = "https://github.com/metabahn/llhttp/".freeze
  s.licenses = ["MPL-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.2.15".freeze
  s.summary = "Ruby FFI bindings for llhttp.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<ffi-compiler>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
end
