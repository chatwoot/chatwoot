require_relative "lib/openai/version"

Gem::Specification.new do |spec|
  spec.name          = "ruby-openai"
  spec.version       = OpenAI::VERSION
  spec.authors       = ["Alex"]
  spec.email         = ["alexrudall@users.noreply.github.com"]

  spec.summary       = "OpenAI API + Ruby! 🤖❤️"
  spec.homepage      = "https://github.com/alexrudall/ruby-openai"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alexrudall/ruby-openai"
  spec.metadata["changelog_uri"] = "https://github.com/alexrudall/ruby-openai/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["funding_uri"] = "https://github.com/sponsors/alexrudall"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "event_stream_parser", ">= 0.3.0", "< 2.0.0"
  spec.add_dependency "faraday", ">= 1"
  spec.add_dependency "faraday-multipart", ">= 1"
end
