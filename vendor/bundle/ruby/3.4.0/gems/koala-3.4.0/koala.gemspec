# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'koala/version'

Gem::Specification.new do |gem|
  gem.name        = "koala"
  gem.summary     = "A lightweight, flexible library for Facebook with support for the Graph API, the REST API, realtime updates, and OAuth authentication."
  gem.description = "Koala is a lightweight, flexible Ruby SDK for Facebook.  It allows read/write access to the social graph via the Graph and REST APIs, as well as support for realtime updates and OAuth and Facebook Connect authentication.  Koala is fully tested and supports Net::HTTP and Typhoeus connections out of the box and can accept custom modules for other services."
  gem.licenses    = ['MIT']
  gem.homepage    = "http://github.com/arsduo/koala"
  gem.version     = Koala::VERSION

  gem.authors     = ["Alex Koppel"]
  gem.email       = "alex@alexkoppel.com"

  gem.require_paths  = ["lib"]
  gem.files          = `git ls-files`.split("\n")
  gem.test_files     = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables    = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  gem.extra_rdoc_files = ["readme.md", "changelog.md"]
  gem.rdoc_options     = ["--line-numbers", "--inline-source", "--title", "Koala"]

  gem.required_ruby_version = '>= 2.1'

  gem.add_runtime_dependency("faraday")
  gem.add_runtime_dependency("faraday-multipart")
  gem.add_runtime_dependency("addressable")
  gem.add_runtime_dependency("json", ">= 1.8")
  gem.add_runtime_dependency("rexml")
end
