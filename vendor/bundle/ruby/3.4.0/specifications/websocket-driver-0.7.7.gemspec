# -*- encoding: utf-8 -*-
# stub: websocket-driver 0.7.7 ruby lib
# stub: ext/websocket-driver/extconf.rb

Gem::Specification.new do |s|
  s.name = "websocket-driver".freeze
  s.version = "0.7.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Coglan".freeze]
  s.date = "2025-01-04"
  s.email = "jcoglan@gmail.com".freeze
  s.extensions = ["ext/websocket-driver/extconf.rb".freeze]
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze, "ext/websocket-driver/extconf.rb".freeze]
  s.homepage = "https://github.com/faye/websocket-driver-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze, "--markup".freeze, "markdown".freeze]
  s.rubygems_version = "3.6.2".freeze
  s.summary = "WebSocket protocol handler with pluggable I/O".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<base64>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<websocket-extensions>.freeze, [">= 0.1.0".freeze])
  s.add_development_dependency(%q<eventmachine>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<permessage_deflate>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
end
