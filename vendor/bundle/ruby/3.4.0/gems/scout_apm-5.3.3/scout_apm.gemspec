# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "scout_apm/version"

Gem::Specification.new do |s|
  s.name        = "scout_apm"
  s.version     = ScoutApm::VERSION
  s.authors     = ["Derek Haynes", 'Andre Lewis']
  s.email       = ["support@scoutapp.com"]
  s.homepage    = "https://github.com/scoutapp/scout_apm_ruby"
  s.summary     = "Ruby application performance monitoring"
  s.description = "Monitors Ruby apps and reports detailed metrics on performance to Scout."
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib","data"]
  s.extensions << 'ext/allocations/extconf.rb'
  s.extensions << 'ext/rusage/extconf.rb'

  s.required_ruby_version = '>= 2.1'

  s.add_development_dependency "minitest"
  s.add_development_dependency "mocha"
  s.add_development_dependency "pry"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rake-compiler"
  s.add_development_dependency "addressable"
  s.add_development_dependency "activesupport"
  s.add_runtime_dependency "parser"

  # These are general development dependencies which are used in instrumentation
  # tests. Specific versions are pulled in using specific gemfiles, e.g. 
  # `gems/rails3.gemfile`.
  s.add_development_dependency "activerecord"
  s.add_development_dependency "sqlite3"

  s.add_development_dependency "rubocop"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-minitest"
  s.add_development_dependency "m"
end
