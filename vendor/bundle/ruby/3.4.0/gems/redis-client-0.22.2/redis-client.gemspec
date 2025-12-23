# frozen_string_literal: true

require_relative "lib/redis_client/version"

Gem::Specification.new do |spec|
  spec.name = "redis-client"
  spec.version = RedisClient::VERSION
  spec.authors = ["Jean Boussier"]
  spec.email = ["jean.boussier@gmail.com"]

  spec.summary = "Simple low-level client for Redis 6+"
  spec.homepage = "https://github.com/redis-rb/redis-client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = File.join(spec.homepage, "blob/master/CHANGELOG.md")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|hiredis-client|test|spec|features|benchmark)/|\.(?:git|rubocop))})
    end
  end
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "connection_pool"
end
