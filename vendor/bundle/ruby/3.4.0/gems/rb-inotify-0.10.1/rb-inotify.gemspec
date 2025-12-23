# -*- encoding: utf-8 -*-
require_relative 'lib/rb-inotify/version'

Gem::Specification.new do |spec|
  spec.name     = 'rb-inotify'
  spec.version  = INotify::VERSION
  spec.platform = Gem::Platform::RUBY

  spec.summary     = 'A Ruby wrapper for Linux inotify, using FFI'
  spec.authors     = ['Natalie Weizenbaum', 'Samuel Williams']
  spec.email       = ['nex342@gmail.com', 'samuel.williams@oriontransfer.co.nz']
  spec.homepage    = 'https://github.com/guard/rb-inotify'
  spec.licenses    = ['MIT']

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.required_ruby_version = '>= 2.2'
  
  spec.add_dependency "ffi", "~> 1.0"
  
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "concurrent-ruby"
end
