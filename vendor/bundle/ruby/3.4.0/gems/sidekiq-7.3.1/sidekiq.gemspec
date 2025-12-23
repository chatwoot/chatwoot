require_relative "lib/sidekiq/version"

Gem::Specification.new do |gem|
  gem.authors = ["Mike Perham"]
  gem.email = ["info@contribsys.com"]
  gem.summary = "Simple, efficient background processing for Ruby"
  gem.description = "Simple, efficient background processing for Ruby."
  gem.homepage = "https://sidekiq.org"
  gem.license = "LGPL-3.0"

  gem.executables = ["sidekiq", "sidekiqmon"]
  gem.files = %w[sidekiq.gemspec README.md Changes.md LICENSE.txt] + `git ls-files | grep -E '^(bin|lib|web)'`.split("\n")
  gem.name = "sidekiq"
  gem.version = Sidekiq::VERSION
  gem.required_ruby_version = ">= 2.7.0"

  gem.metadata = {
    "homepage_uri" => "https://sidekiq.org",
    "bug_tracker_uri" => "https://github.com/sidekiq/sidekiq/issues",
    "documentation_uri" => "https://github.com/sidekiq/sidekiq/wiki",
    "changelog_uri" => "https://github.com/sidekiq/sidekiq/blob/main/Changes.md",
    "source_code_uri" => "https://github.com/sidekiq/sidekiq",
    "rubygems_mfa_required" => "true"
  }

  gem.add_dependency "redis-client", ">= 0.22.2"
  gem.add_dependency "connection_pool", ">= 2.3.0"
  gem.add_dependency "rack", ">= 2.2.4"
  gem.add_dependency "concurrent-ruby", "< 2"
  gem.add_dependency "logger"
end
