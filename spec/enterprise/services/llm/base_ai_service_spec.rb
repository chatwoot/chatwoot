require 'rails_helper'

RSpec.describe Llm::BaseAiService do
  subject(:service) { described_class.new }

  let(:account) { create(:account) }

  before do
    InstallationConfig.where(name: %w[CAPTAIN_OPEN_AI_API_KEY CAPTAIN_OPEN_AI_MODEL]).destroy_all
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
  end

  describe '#initialize' do
    it 'uses the installation model when no feature is provided' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1-nano')

      expect(described_class.new.model).to eq('gpt-4.1-nano')
    end

    it 'uses the account override when feature context is provided' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1-nano')
      account.update!(captain_models: { 'assistant' => 'gpt-5.2' })

      expect(described_class.new(feature: 'assistant', account: account).model).to eq('gpt-5.2')
    end

    it 'uses the installation model when feature context has no account override' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1-nano')

      expect(described_class.new(feature: 'assistant', account: account).model).to eq('gpt-4.1-nano')
    end

    it 'uses the Captain V2 assistant default ahead of the installation model' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1-nano')
      account.enable_features!('captain_integration')

      expect(described_class.new(feature: 'assistant', account: account).model).to eq('gpt-5.2')
      expect(account.reload.captain_models).to be_nil
    end

    it 'uses the feature default when feature context has no account override or installation model' do
      expect(described_class.new(feature: 'assistant', account: account).model).to eq(Llm::Models.default_model_for('assistant'))
    end
  end

  describe 'routed request format' do
    it 'uses Responses JSON mode and the requested effort for a shared text flow' do
      allow(Llm::FeatureRouter).to receive(:reasoning_effort).and_call_original
      allow(Llm::FeatureRouter).to receive(:reasoning_effort).with(feature: 'document_faq_generation', model: 'gpt-5.2').and_return(:high)
      chat = described_class.new(feature: 'document_faq_generation', account: account).json_chat(model: 'gpt-5.2')
      chat.with_instructions('Generate FAQs as JSON.').add_message(role: :user, content: 'Acme opens at 9 am.')

      expect(chat.render).to include(input: an_instance_of(Array), text: { format: { type: 'json_object' } }, reasoning: { effort: 'high' })
      expect(chat.render[:input].to_json).to include('Respond with valid JSON.')
      expect(chat.render).not_to have_key(:temperature)
      expect(chat.render).not_to have_key(:response_format)
    end

    it 'retains the existing JSON format and protocol on custom endpoints' do
      InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT').update!(value: 'https://custom.example')
      chat = described_class.new(feature: 'document_faq_generation', account: account).json_chat(model: 'gpt-4.1')
      chat.add_message(role: :user, content: 'Generate JSON FAQs.')

      expect(chat.render).to include(messages: an_instance_of(Array), response_format: { type: 'json_object' })
      expect(chat.render).not_to have_key(:reasoning)
      expect(chat.render).not_to have_key(:input)
    end
  end

  describe '#sanitize_json_response' do
    it 'strips ```json fences' do
      input = "```json\n{\"key\": \"value\"}\n```"
      expect(service.send(:sanitize_json_response, input)).to eq('{"key": "value"}')
    end

    it 'strips bare ``` fences' do
      input = "```\n{\"key\": \"value\"}\n```"
      expect(service.send(:sanitize_json_response, input)).to eq('{"key": "value"}')
    end

    it 'passes through plain JSON unchanged' do
      input = '{"key": "value"}'
      expect(service.send(:sanitize_json_response, input)).to eq('{"key": "value"}')
    end

    it 'returns nil for nil input' do
      expect(service.send(:sanitize_json_response, nil)).to be_nil
    end

    it 'strips surrounding whitespace' do
      input = "  \n{\"key\": \"value\"}\n  "
      expect(service.send(:sanitize_json_response, input)).to eq('{"key": "value"}')
    end
  end

  describe '#chat' do
    %w[gpt-5.1 gpt-5.2].each do |model|
      it "omits temperature for #{model} when the model registry marks it unsupported" do
        llm_chat = instance_double(RubyLLM::Chat)
        allow(RubyLLM).to receive(:chat).with(model: model, protocol: :responses).and_return(llm_chat)

        expect(llm_chat).not_to receive(:with_temperature)
        expect(service.chat(model: model)).to eq(llm_chat)
      end
    end

    it 'sets temperature when the model registry marks it supported' do
      llm_chat = instance_double(RubyLLM::Chat)
      configured_chat = instance_double(RubyLLM::Chat)
      allow(RubyLLM).to receive(:chat).with(model: 'gpt-4.1-mini', protocol: :responses).and_return(llm_chat)
      allow(llm_chat).to receive(:with_temperature).with(0.7).and_return(configured_chat)

      expect(service.chat(model: 'gpt-4.1-mini', temperature: 0.7)).to eq(configured_chat)
    end
  end
end
