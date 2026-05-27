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

    it 'returns false for custom OpenAI-compatible endpoints' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'custom')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.groq.com/openai')

      expect(described_class.supports_structured_outputs_with_tools?).to be false
    end

    it 'returns false for named providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')

      expect(described_class.supports_structured_outputs_with_tools?).to be false
    end
  end

  describe '.captain_utility_model' do
    it 'uses gpt-4.1-nano for OpenAI with the default endpoint' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', '')
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'gpt-4.1')

      expect(described_class.captain_utility_model).to eq('gpt-4.1-nano')
    end

    it 'uses the configured Captain model for custom providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'custom')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.fireworks.ai/inference/v1')
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'accounts/fireworks/models/kimi-k2p6')

      expect(described_class.captain_utility_model).to eq('accounts/fireworks/models/kimi-k2p6')
    end
  end

  describe '.api_base_for' do
    it 'normalizes pasted chat completions URLs to the API base URL' do
      expect(
        described_class.api_base_for(provider: 'custom', endpoint: 'https://api.groq.com/openai/v1/chat/completions/')
      ).to eq('https://api.groq.com/openai/v1')
    end
  end

  describe '.provider_options' do
    it 'includes a custom OpenAI-compatible option' do
      expect(described_class.provider_options).to include('custom' => 'Custom (OpenAI-compatible)')
    end
  end

  describe '.provider_api_base_options' do
    it 'derives API base defaults from RubyLLM providers' do
      expect(described_class.provider_api_base_options).to include(
        'openai' => 'https://api.openai.com/v1',
        'gemini' => 'https://generativelanguage.googleapis.com/v1beta',
        'openrouter' => 'https://openrouter.ai/api/v1',
        'custom' => ''
      )
    end
  end

  describe '.ruby_llm_provider' do
    it 'maps custom providers to the OpenAI adapter' do
      expect(described_class.ruby_llm_provider('custom')).to eq('openai')
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

    it 'configures custom providers through OpenAI-compatible settings' do
      config = Class.new do
        attr_accessor :openai_api_key, :openai_api_base
      end.new

      described_class.configure_provider(config, provider: 'custom', api_key: 'test-key', api_base: 'https://api.groq.com/openai/v1')

      expect(config.openai_api_key).to eq('test-key')
      expect(config.openai_api_base).to eq('https://api.groq.com/openai/v1')
    end
  end
end
