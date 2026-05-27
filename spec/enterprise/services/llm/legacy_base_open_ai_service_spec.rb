require 'rails_helper'

RSpec.describe Llm::LegacyBaseOpenAiService do
  let(:openai_client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
  end

  it 'uses the OpenAI-only key and default OpenAI base for OpenAI file APIs' do
    set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
    set_installation_config('CAPTAIN_OPEN_AI_API_KEY', 'provider-key')
    set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://openrouter.ai/api')
    set_installation_config('CAPTAIN_EMBEDDING_API_KEY', 'openai-key')

    described_class.new

    expect(OpenAI::Client).to have_received(:new).with(
      access_token: 'openai-key',
      uri_base: Llm::OpenAiConfig.api_base,
      log_errors: Rails.env.development?
    )
  end

  it 'falls back to the Captain LLM key for the default OpenAI endpoint' do
    set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
    set_installation_config('CAPTAIN_OPEN_AI_API_KEY', 'openai-key')
    set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://api.openai.com/v1')
    set_installation_config('CAPTAIN_EMBEDDING_API_KEY', '')

    described_class.new

    expect(OpenAI::Client).to have_received(:new).with(
      access_token: 'openai-key',
      uri_base: Llm::OpenAiConfig.api_base,
      log_errors: Rails.env.development?
    )
  end

  it 'raises clearly when OpenAI-only features do not have an OpenAI key' do
    set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
    set_installation_config('CAPTAIN_OPEN_AI_API_KEY', 'provider-key')
    set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://openrouter.ai/api')
    set_installation_config('CAPTAIN_EMBEDDING_API_KEY', '')

    expect { described_class.new }.to raise_error(Llm::ConfigurationError, /OpenAI API key is required/)
    expect(OpenAI::Client).not_to have_received(:new)
  end
end
