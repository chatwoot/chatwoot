require "./lib/connection_pool/version"

Gem::Specification.new do |s|
  s.name = "connection_pool"
  s.version = ConnectionPool::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Mike Perham", "Damian Janowski"]
  s.email = ["mperham@gmail.com", "damian@educabilia.com"]
  s.homepage = "https://github.com/mperham/connection_pool"
  s.description = s.summary = "Generic connection pool for Ruby"

  s.files = ["Changes.md", "LICENSE", "README.md", "connection_pool.gemspec",
    "lib/connection_pool.rb", "lib/connection_pool/timed_stack.rb",
    "lib/connection_pool/version.rb", "lib/connection_pool/wrapper.rb"]
  s.executables = []
  s.require_paths = ["lib"]
  s.license = "MIT"
  s.add_development_dependency "bundler"
  s.add_development_dependency "minitest", ">= 5.0.0"
  s.add_development_dependency "rake"
  s.required_ruby_version = ">= 2.5.0"

  s.metadata = {"changelog_uri" => "https://github.com/mperham/connection_pool/blob/main/Changes.md", "rubygems_mfa_required" => "true"}
end
