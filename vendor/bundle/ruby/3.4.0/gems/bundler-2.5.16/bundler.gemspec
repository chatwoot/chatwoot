# frozen_string_literal: true

begin
  require_relative "lib/bundler/version"
rescue LoadError
  # for Ruby core repository
  require_relative "version"
end

Gem::Specification.new do |s|
  s.name        = "bundler"
  s.version     = Bundler::VERSION
  s.license     = "MIT"
  s.authors     = [
    "André Arko", "Samuel Giddins", "Colby Swandale", "Hiroshi Shibata",
    "David Rodríguez", "Grey Baker", "Stephanie Morillo", "Chris Morris", "James Wen", "Tim Moore",
    "André Medeiros", "Jessica Lynn Suttles", "Terence Lee", "Carl Lerche",
    "Yehuda Katz"
  ]
  s.email       = ["team@bundler.io"]
  s.homepage    = "https://bundler.io"
  s.summary     = "The best way to manage your application's dependencies"
  s.description = "Bundler manages an application's dependencies through its entire life, across many machines, systematically and repeatably"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/rubygems/rubygems/issues?q=is%3Aopen+is%3Aissue+label%3ABundler",
    "changelog_uri" => "https://github.com/rubygems/rubygems/blob/master/bundler/CHANGELOG.md",
    "homepage_uri" => "https://bundler.io/",
    "source_code_uri" => "https://github.com/rubygems/rubygems/tree/master/bundler",
  }

  s.required_ruby_version     = ">= 3.0.0"

  # It should match the RubyGems version shipped with `required_ruby_version` above
  s.required_rubygems_version = ">= 3.2.3"

  s.files = Dir.glob("lib/bundler{.rb,/**/*}", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }

  # include the gemspec itself because warbler breaks w/o it
  s.files += %w[bundler.gemspec]

  s.files += %w[CHANGELOG.md LICENSE.md README.md]
  s.bindir        = "exe"
  s.executables   = %w[bundle bundler]
  s.require_paths = ["lib"]
end
