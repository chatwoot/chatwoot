# frozen_string_literal: true

require_relative "../lib/agents"

RSpec.describe Agents do
  describe "module structure" do
    it "defines the main module" do
      expect(described_class).to be_a(Module)
    end

    it "defines Error class" do
      expect(Agents::Error).to be < StandardError
    end

    it "defines RECOMMENDED_HANDOFF_PROMPT_PREFIX constant" do
      expect(described_class::RECOMMENDED_HANDOFF_PROMPT_PREFIX).to be_a(String)
      expect(described_class::RECOMMENDED_HANDOFF_PROMPT_PREFIX).to include("multi-agent system")
      expect(described_class::RECOMMENDED_HANDOFF_PROMPT_PREFIX).to include("Ruby Agents SDK")
      expect(described_class::RECOMMENDED_HANDOFF_PROMPT_PREFIX).to include("handoff_to_")
    end
  end

  describe ".logger" do
    it "allows setting and getting logger" do
      logger = instance_double(Logger)
      described_class.logger = logger
      expect(described_class.logger).to eq(logger)
    end
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(Agents::Configuration)
    end

    it "returns the same instance on multiple calls" do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".configure" do
    let(:mock_ruby_llm_config) do
      Class.new do
        attr_writer :openai_api_key, :openai_api_base, :openai_organization_id, :openai_project_id,
                    :anthropic_api_key, :gemini_api_key, :deepseek_api_key, :openrouter_api_key,
                    :ollama_api_base, :bedrock_api_key, :bedrock_secret_key, :bedrock_region,
                    :bedrock_session_token, :default_model, :log_level, :request_timeout
        attr_reader :log_level
      end.new
    end

    before do
      # Reset configuration for testing
      described_class.instance_variable_set(:@configuration, nil)
    end

    it "yields configuration to the block" do
      yielded_config = nil
      described_class.configure do |config|
        yielded_config = config
      end
      expect(yielded_config).to be_a(Agents::Configuration)
    end

    it "configures RubyLLM with openai_api_key" do
      allow(RubyLLM).to receive(:configure)

      described_class.configure do |config|
        config.openai_api_key = "test-key"
      end

      expect(RubyLLM).to have_received(:configure)
    end

    it "configures RubyLLM with anthropic_api_key" do
      allow(RubyLLM).to receive(:configure)

      described_class.configure do |config|
        config.anthropic_api_key = "test-anthropic-key"
      end

      expect(RubyLLM).to have_received(:configure)
    end

    it "configures RubyLLM with gemini_api_key" do
      allow(RubyLLM).to receive(:configure)

      described_class.configure do |config|
        config.gemini_api_key = "test-gemini-key"
      end

      expect(RubyLLM).to have_received(:configure)
    end

    it "sets debug log level when debug is true" do
      allow(RubyLLM).to receive(:configure).and_yield(mock_ruby_llm_config)

      described_class.configure do |config|
        config.debug = true
      end

      expect(mock_ruby_llm_config.log_level).to eq(:debug)
    end

    it "sets info log level when debug is false" do
      allow(RubyLLM).to receive(:configure).and_yield(mock_ruby_llm_config)

      described_class.configure do |config|
        config.debug = false
      end

      expect(mock_ruby_llm_config.log_level).to eq(:info)
    end

    it "returns the configuration instance" do
      result = described_class.configure {}
      expect(result).to be_a(Agents::Configuration)
    end

    it "configures RubyLLM with all new provider keys" do
      allow(RubyLLM).to receive(:configure)

      described_class.configure do |config|
        config.openai_api_base = "https://custom.openai.com"
        config.openai_organization_id = "org-123"
        config.openai_project_id = "proj-456"
        config.deepseek_api_key = "test-deepseek"
        config.openrouter_api_key = "test-openrouter"
        config.ollama_api_base = "http://localhost:11434"
        config.bedrock_api_key = "test-bedrock-key"
        config.bedrock_secret_key = "test-bedrock-secret"
        config.bedrock_region = "us-east-1"
        config.bedrock_session_token = "test-session"
      end

      expect(RubyLLM).to have_received(:configure)
    end
  end
end

RSpec.describe Agents::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.default_model).to eq("gpt-4o-mini")
      expect(config.request_timeout).to eq(120)
      expect(config.debug).to be false
    end

    it "initializes API keys as nil" do
      expect(config.openai_api_key).to be_nil
      expect(config.openai_api_base).to be_nil
      expect(config.openai_organization_id).to be_nil
      expect(config.openai_project_id).to be_nil
      expect(config.anthropic_api_key).to be_nil
      expect(config.gemini_api_key).to be_nil
      expect(config.deepseek_api_key).to be_nil
      expect(config.openrouter_api_key).to be_nil
      expect(config.ollama_api_base).to be_nil
      expect(config.bedrock_api_key).to be_nil
      expect(config.bedrock_secret_key).to be_nil
      expect(config.bedrock_region).to be_nil
      expect(config.bedrock_session_token).to be_nil
    end
  end

  describe "attribute accessors" do
    it "allows setting and getting openai_api_key" do
      config.openai_api_key = "test-openai-key"
      expect(config.openai_api_key).to eq("test-openai-key")
    end

    it "allows setting and getting anthropic_api_key" do
      config.anthropic_api_key = "test-anthropic-key"
      expect(config.anthropic_api_key).to eq("test-anthropic-key")
    end

    it "allows setting and getting gemini_api_key" do
      config.gemini_api_key = "test-gemini-key"
      expect(config.gemini_api_key).to eq("test-gemini-key")
    end

    it "allows setting and getting request_timeout" do
      config.request_timeout = 300
      expect(config.request_timeout).to eq(300)
    end

    it "allows setting and getting default_model" do
      config.default_model = "gpt-4"
      expect(config.default_model).to eq("gpt-4")
    end

    it "allows setting and getting debug" do
      config.debug = true
      expect(config.debug).to be true
    end

    it "allows setting and getting openai_api_base" do
      config.openai_api_base = "https://custom.openai.com"
      expect(config.openai_api_base).to eq("https://custom.openai.com")
    end

    it "allows setting and getting openai_organization_id" do
      config.openai_organization_id = "org-123"
      expect(config.openai_organization_id).to eq("org-123")
    end

    it "allows setting and getting openai_project_id" do
      config.openai_project_id = "proj-456"
      expect(config.openai_project_id).to eq("proj-456")
    end

    it "allows setting and getting deepseek_api_key" do
      config.deepseek_api_key = "test-deepseek-key"
      expect(config.deepseek_api_key).to eq("test-deepseek-key")
    end

    it "allows setting and getting openrouter_api_key" do
      config.openrouter_api_key = "test-openrouter-key"
      expect(config.openrouter_api_key).to eq("test-openrouter-key")
    end

    it "allows setting and getting ollama_api_base" do
      config.ollama_api_base = "http://localhost:11434"
      expect(config.ollama_api_base).to eq("http://localhost:11434")
    end

    it "allows setting and getting bedrock credentials" do
      config.bedrock_api_key = "test-bedrock-key"
      config.bedrock_secret_key = "test-bedrock-secret"
      config.bedrock_region = "us-east-1"
      config.bedrock_session_token = "test-session-token"

      expect(config.bedrock_api_key).to eq("test-bedrock-key")
      expect(config.bedrock_secret_key).to eq("test-bedrock-secret")
      expect(config.bedrock_region).to eq("us-east-1")
      expect(config.bedrock_session_token).to eq("test-session-token")
    end
  end

  describe "#configured?" do
    it "returns false when no API keys are set" do
      expect(config).not_to be_configured
    end

    it "returns truthy when openai_api_key is set" do
      config.openai_api_key = "test-key"
      expect(config).to be_configured
    end

    it "returns truthy when anthropic_api_key is set" do
      config.anthropic_api_key = "test-key"
      expect(config).to be_configured
    end

    it "returns truthy when gemini_api_key is set" do
      config.gemini_api_key = "test-key"
      expect(config).to be_configured
    end

    it "returns truthy when multiple API keys are set" do
      config.openai_api_key = "openai-key"
      config.anthropic_api_key = "anthropic-key"
      expect(config).to be_configured
    end

    it "returns truthy when deepseek_api_key is set" do
      config.deepseek_api_key = "test-key"
      expect(config).to be_configured
    end

    it "returns truthy when openrouter_api_key is set" do
      config.openrouter_api_key = "test-key"
      expect(config).to be_configured
    end

    it "returns truthy when ollama_api_base is set" do
      config.ollama_api_base = "http://localhost:11434"
      expect(config).to be_configured
    end

    it "returns truthy when bedrock_api_key is set" do
      config.bedrock_api_key = "test-key"
      expect(config).to be_configured
    end
  end
end
