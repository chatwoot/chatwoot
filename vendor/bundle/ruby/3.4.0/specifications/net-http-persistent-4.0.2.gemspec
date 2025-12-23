# -*- encoding: utf-8 -*-
# stub: net-http-persistent 4.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "net-http-persistent".freeze
  s.version = "4.0.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/drbrain/net-http-persistent" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eric Hodel".freeze]
  s.date = "2023-03-29"
  s.description = "Manages persistent connections using Net::HTTP including a thread pool for\nconnecting to multiple hosts.\n\nUsing persistent HTTP connections can dramatically increase the speed of HTTP.\nCreating a new HTTP connection for every request involves an extra TCP\nround-trip and causes TCP congestion avoidance negotiation to start over.\n\nNet::HTTP supports persistent connections with some API methods but does not\nmake setting up a single persistent connection or managing multiple\nconnections easy.  Net::HTTP::Persistent wraps Net::HTTP and allows you to\nfocus on how to make HTTP requests.".freeze
  s.email = ["drbrain@segment7.net".freeze]
  s.extra_rdoc_files = ["History.txt".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.files = ["History.txt".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.homepage = "https://github.com/drbrain/net-http-persistent".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Manages persistent connections using Net::HTTP including a thread pool for connecting to multiple hosts".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<connection_pool>.freeze, ["~> 2.2".freeze])
end
