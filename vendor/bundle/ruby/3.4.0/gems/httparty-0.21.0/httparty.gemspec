# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "httparty/version"

Gem::Specification.new do |s|
  s.name        = "httparty"
  s.version     = HTTParty::VERSION
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ['MIT']
  s.authors     = ["John Nunemaker", "Sandro Turriate"]
  s.email       = ["nunemaker@gmail.com"]
  s.homepage    = "https://github.com/jnunemaker/httparty"
  s.summary     = 'Makes http fun! Also, makes consuming restful web services dead easy.'
  s.description = 'Makes http fun! Also, makes consuming restful web services dead easy.'

  s.required_ruby_version     = '>= 2.3.0'

  s.add_dependency 'multi_xml', ">= 0.5.2"
  s.add_dependency 'mini_mime', ">= 1.0.0"

  # If this line is removed, all hard partying will cease.
  s.post_install_message = "When you HTTParty, you must party hard!"

  all_files = `git ls-files`.split("\n")
  test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.files         = all_files - test_files
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]
end
