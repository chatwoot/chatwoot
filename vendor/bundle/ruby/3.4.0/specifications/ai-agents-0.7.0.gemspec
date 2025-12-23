# -*- encoding: utf-8 -*-
# stub: ai-agents 0.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ai-agents".freeze
  s.version = "0.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/chatwoot/ai-agents", "homepage_uri" => "https://chatwoot.com/ai-agents", "source_code_uri" => "https://github.com/chatwoot/ai-agents" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Shivam Mishra".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "Ruby AI Agents SDK enables creating complex AI workflows with multi-agent orchestration, tool execution, safety guardrails, and provider-agnostic LLM integration.".freeze
  s.email = ["scm.mymail@gmail.com".freeze]
  s.homepage = "https://chatwoot.com/ai-agents".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.6.7".freeze
  s.summary = "A Ruby SDK for building sophisticated multi-agent AI workflows".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<ruby_llm>.freeze, ["~> 1.8.2".freeze])
end
