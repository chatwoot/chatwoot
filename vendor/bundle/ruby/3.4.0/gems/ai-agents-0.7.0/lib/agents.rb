# frozen_string_literal: true

# Main entry point for the Ruby AI Agents SDK
# This file sets up the core Agents module namespace and provides global configuration
# for the multi-agent system including LLM provider setup, API keys, and system defaults.
# It serves as the central configuration hub that other components depend on.

require "ruby_llm"
require_relative "agents/version"

module Agents
  class Error < StandardError; end

  # OpenAI's recommended system prompt prefix for multi-agent workflows
  # This helps agents understand they're part of a coordinated system
  RECOMMENDED_HANDOFF_PROMPT_PREFIX =
    "# System context\n" \
    "You are part of a multi-agent system called the Ruby Agents SDK, designed to make agent " \
    "coordination and execution easy. Agents uses two primary abstraction: **Agents** and " \
    "**Handoffs**. An agent encompasses instructions and tools and can hand off a " \
    "conversation to another agent when appropriate. " \
    "Handoffs are achieved by calling a handoff function, generally named " \
    "`handoff_to_<agent_name>`. Transfers between agents are handled seamlessly in the background; " \
    "do not mention or draw attention to these transfers in your conversation with the user.\n"

  class << self
    # Logger for debugging (can be set by users)
    attr_accessor :logger

    # Configure both Agents and RubyLLM in one block
    def configure
      yield(configuration) if block_given?
      configure_ruby_llm!
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    private

    def configure_ruby_llm!
      RubyLLM.configure do |config|
        configure_providers(config)
        configure_general_settings(config)
      end
    end

    def configure_providers(config)
      # OpenAI configuration
      apply_if_present(config, :openai_api_key)
      apply_if_present(config, :openai_api_base)
      apply_if_present(config, :openai_organization_id)
      apply_if_present(config, :openai_project_id)

      # Other providers
      apply_if_present(config, :anthropic_api_key)
      apply_if_present(config, :gemini_api_key)
      apply_if_present(config, :deepseek_api_key)
      apply_if_present(config, :openrouter_api_key)
      apply_if_present(config, :ollama_api_base)

      # AWS Bedrock configuration
      apply_if_present(config, :bedrock_api_key)
      apply_if_present(config, :bedrock_secret_key)
      apply_if_present(config, :bedrock_region)
      apply_if_present(config, :bedrock_session_token)
    end

    def configure_general_settings(config)
      config.default_model = configuration.default_model
      config.log_level = configuration.debug == true ? :debug : :info
      apply_if_present(config, :request_timeout)
    end

    def apply_if_present(config, key)
      value = configuration.send(key)
      config.send("#{key}=", value) if value
    end
  end

  class Configuration
    # Provider API keys and configuration
    attr_accessor :openai_api_key, :openai_api_base, :openai_organization_id, :openai_project_id
    attr_accessor :anthropic_api_key, :gemini_api_key, :deepseek_api_key, :openrouter_api_key, :ollama_api_base,
                  :bedrock_api_key, :bedrock_secret_key, :bedrock_region, :bedrock_session_token

    # General configuration
    attr_accessor :request_timeout, :default_model, :debug

    def initialize
      @default_model = "gpt-4o-mini"
      @request_timeout = 120
      @debug = false
    end

    # Check if at least one provider is configured
    # @return [Boolean] True if any provider has an API key
    def configured?
      @openai_api_key || @anthropic_api_key || @gemini_api_key ||
        @deepseek_api_key || @openrouter_api_key || @ollama_api_base ||
        @bedrock_api_key
    end
  end
end

# Core components
require_relative "agents/result"
require_relative "agents/run_context"
require_relative "agents/tool_context"
require_relative "agents/tool"
require_relative "agents/handoff"
require_relative "agents/helpers"
require_relative "agents/agent"

# Execution components
require_relative "agents/tool_wrapper"
require_relative "agents/callback_manager"
require_relative "agents/agent_runner"
require_relative "agents/runner"
require_relative "agents/agent_tool"
