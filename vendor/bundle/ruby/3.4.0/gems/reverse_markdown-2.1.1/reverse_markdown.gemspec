# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "reverse_markdown/version"

Gem::Specification.new do |s|
  s.name        = "reverse_markdown"
  s.version     = ReverseMarkdown::VERSION
  s.authors     = ["Johannes Opper"]
  s.email       = ["johannes.opper@gmail.com"]
  s.homepage    = "http://github.com/xijo/reverse_markdown"
  s.summary     = %q{Convert html code into markdown.}
  s.description = %q{Map simple html back into markdown, e.g. if you want to import existing html data in your application.}
  s.licenses    = ["WTFPL"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_dependency 'nokogiri'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'kramdown'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'codeclimate-test-reporter'
end
