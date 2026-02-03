# frozen_string_literal: true

require_relative "lib/agents/version"

Gem::Specification.new do |spec|
  spec.name = "ai-agents"
  spec.version = Agents::VERSION
  spec.authors = ["Shivam Mishra"]
  spec.email = ["scm.mymail@gmail.com"]

  spec.summary = "A Ruby SDK for building sophisticated multi-agent AI workflows"
  spec.description = "Ruby AI Agents SDK enables creating complex AI workflows with multi-agent orchestration, tool execution, safety guardrails, and provider-agnostic LLM integration."
  spec.homepage = "https://chatwoot.com/ai-agents"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/chatwoot/ai-agents"
  spec.metadata["changelog_uri"] = "https://github.com/chatwoot/ai-agents"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "ruby_llm", "~> 1.9.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
