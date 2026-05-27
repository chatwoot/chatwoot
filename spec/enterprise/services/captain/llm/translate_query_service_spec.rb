require 'rails_helper'

RSpec.describe Captain::Llm::TranslateQueryService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  before do
    allow(service).to receive(:query_in_target_language?).and_return(false)
  end

  describe '#translate' do
    it 'uses the OpenAI utility model by default' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openai')
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'gpt-4.1')

      expect(service).to receive(:make_api_call)
        .with(model: 'gpt-4.1-nano', messages: kind_of(Array))
        .and_return(message: 'bonjour')

      expect(service.translate('hello', target_language: 'French')).to eq('bonjour')
    end

    it 'uses the configured Captain model for custom providers' do
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'custom')
      set_installation_config('CAPTAIN_OPEN_AI_MODEL', 'accounts/fireworks/models/kimi-k2p6')

      expect(service).to receive(:make_api_call)
        .with(model: 'accounts/fireworks/models/kimi-k2p6', messages: kind_of(Array))
        .and_return(message: 'bonjour')

      expect(service.translate('hello', target_language: 'French')).to eq('bonjour')
    end
  end
end
