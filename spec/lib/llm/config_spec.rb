require 'rails_helper'

RSpec.describe Llm::Config do
  describe '.default_openai_endpoint?' do
    it 'returns true when OpenAI provider uses the default endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.openai.com')

      expect(described_class.default_openai_endpoint?).to be true
    end

    it 'returns true when OpenAI provider uses the default endpoint with /v1' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.openai.com/v1')

      expect(described_class.default_openai_endpoint?).to be true
    end

    it 'returns true when OpenAI provider uses the default chat completions URL' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.openai.com/v1/chat/completions')

      expect(described_class.default_openai_endpoint?).to be true
    end

    it 'returns false when OpenAI provider uses a custom endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://example.com/v1')

      expect(described_class.default_openai_endpoint?).to be false
    end

    it 'returns false for other providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')

      expect(described_class.default_openai_endpoint?).to be false
    end
  end

  describe '.supports_structured_outputs_with_tools?' do
    it 'returns true for OpenAI with the default endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')

      expect(described_class.supports_structured_outputs_with_tools?).to be true
    end

    it 'returns false for named providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')

      expect(described_class.supports_structured_outputs_with_tools?).to be false
    end
  end

  describe '.supports_temperature?' do
    it 'returns true for OpenAI with the default endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')

      expect(described_class.supports_temperature?).to be true
    end

    it 'returns false for named providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'anthropic')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.anthropic.com')

      expect(described_class.supports_temperature?).to be false
    end
  end

  describe '.supports_openai_chat_params?' do
    it 'returns true for OpenAI-shaped providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')

      expect(described_class.supports_openai_chat_params?).to be true
    end

    it 'returns false for providers with different payload shapes' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'gemini')

      expect(described_class.supports_openai_chat_params?).to be false
    end
  end

  describe '.direct_openai_endpoint?' do
    it 'returns true for OpenAI with a blank endpoint' do
      expect(described_class.direct_openai_endpoint?(provider: 'openai', endpoint: '')).to be true
    end

    it 'returns true for OpenAI chat completions URLs' do
      expect(described_class.direct_openai_endpoint?(provider: 'openai', endpoint: 'https://api.openai.com/v1/chat/completions')).to be true
    end

    it 'returns false for OpenAI endpoint overrides' do
      expect(described_class.direct_openai_endpoint?(provider: 'openai', endpoint: 'https://llm.example.com/v1')).to be false
    end
  end

  describe '.captain_utility_model' do
    it 'uses gpt-4.1-nano for OpenAI with the default endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'gpt-4.1')

      expect(described_class.captain_utility_model).to eq('gpt-4.1-nano')
    end

    it 'uses the configured Captain model for named non-OpenAI providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'openai/gpt-4o-mini')

      expect(described_class.captain_utility_model).to eq('openai/gpt-4o-mini')
    end
  end

  describe '.provider_api_base_options' do
    it 'derives API base defaults from RubyLLM providers' do
      expect(described_class.provider_api_base_options).to include(
        'openai' => 'https://api.openai.com/v1',
        'gemini' => 'https://generativelanguage.googleapis.com/v1beta',
        'openrouter' => 'https://openrouter.ai/api/v1'
      )
    end
  end

  describe '.ruby_llm_provider' do
    it 'returns the selected RubyLLM provider' do
      expect(described_class.ruby_llm_provider('openrouter')).to eq('openrouter')
    end
  end

  describe '.captain_model_for' do
    it 'keeps the requested task model for OpenAI with the default endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'gpt-4.1')

      expect(described_class.captain_model_for('gpt-4.1-nano')).to eq('gpt-4.1-nano')
    end

    it 'uses the configured Captain model for named non-OpenAI providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'openai/gpt-4o-mini')

      expect(described_class.captain_model_for('gpt-4.1-nano')).to eq('openai/gpt-4o-mini')
    end

    it 'uses the configured Captain model for OpenAI custom endpoints' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://llm.example.com/v1')
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'local-model')

      expect(described_class.captain_model_for('gpt-4.1-nano')).to eq('local-model')
    end
  end

  describe '.api_key_required?' do
    it 'returns true for API-key providers' do
      expect(described_class.api_key_required?('openai')).to be true
    end

    it 'returns true for Azure because this config only supports azure_api_key credentials' do
      expect(described_class.api_key_required?('azure')).to be true
    end

    it 'returns false for API-base-only providers' do
      expect(described_class.api_key_required?('ollama')).to be false
    end
  end

  describe '.api_base_only_provider_configured?' do
    it 'returns true when an API-base-only provider has an endpoint' do
      expect(
        described_class.api_base_only_provider_configured?(provider: 'ollama', endpoint: 'http://localhost:11434')
      ).to be true
    end

    it 'returns false when an API-base-only provider has no endpoint' do
      expect(described_class.api_base_only_provider_configured?(provider: 'ollama', endpoint: '')).to be false
    end

    it 'returns false for providers that require API keys' do
      expect(
        described_class.api_base_only_provider_configured?(provider: 'openrouter', endpoint: 'https://openrouter.ai/api/v1')
      ).to be false
    end
  end

  describe '.configure_provider' do
    it 'ignores provider settings unsupported by the target config object' do
      config = Class.new do
        attr_accessor :openai_api_key
      end.new

      expect do
        described_class.configure_provider(config, provider: 'openai', api_key: 'test-key', api_base: 'https://example.com')
      end.not_to raise_error

      expect(config.openai_api_key).to eq('test-key')
    end

    it 'configures named providers through their RubyLLM settings' do
      config = Class.new do
        attr_accessor :openrouter_api_key, :openrouter_api_base
      end.new

      described_class.configure_provider(config, provider: 'openrouter', api_key: 'test-key', api_base: 'https://openrouter.ai/api/v1')

      expect(config.openrouter_api_key).to eq('test-key')
      expect(config.openrouter_api_base).to eq('https://openrouter.ai/api/v1')
    end

    it 'configures Azure auth token when provided' do
      config = Class.new do
        attr_accessor :azure_api_base, :azure_api_key, :azure_ai_auth_token
      end.new

      described_class.configure_provider(
        config,
        provider: 'azure',
        api_key: nil,
        api_base: 'https://example.openai.azure.com',
        auth_token: 'azure-token'
      )

      expect(config.azure_api_base).to eq('https://example.openai.azure.com')
      expect(config.azure_api_key).to be_nil
      expect(config.azure_ai_auth_token).to eq('azure-token')
    end
  end
end
