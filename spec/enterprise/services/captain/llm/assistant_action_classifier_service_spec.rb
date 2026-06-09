require 'rails_helper'

RSpec.describe Captain::Llm::AssistantActionClassifierService do
  let(:account) { create(:account) }
  let(:assistant) do
    create(
      :captain_assistant,
      account: account,
      config: {
        'instructions' => 'Only transfer to a manager after the user explicitly confirms.'
      }
    )
  end
  let(:conversation) { create(:conversation, account: account) }
  let(:service) { described_class.new(assistant: assistant, conversation: conversation) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_response) do
    instance_double(
      RubyLLM::Message,
      content: { 'action' => 'handoff', 'action_reason' => 'human_offer_accepted' }
    )
  end

  before do
    allow(RubyLLM).to receive(:chat).and_return(mock_chat)
    allow(mock_chat).to receive(:with_temperature).and_return(mock_chat)
    allow(mock_chat).to receive(:with_schema).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
  end

  describe '#classify' do
    let(:message_history) do
      [
        { role: 'user', content: 'I cannot log in' },
        { role: 'assistant', content: 'Did you check your inbox?' },
        { role: 'user', content: 'Yes, still no reset email' }
      ]
    end

    it 'passes delimited custom instructions and classifier context to the LLM' do
      expect(mock_chat).to receive(:with_schema).with(Captain::AssistantActionSchema).and_return(mock_chat)
      expect(mock_chat).to receive(:with_instructions).with(
        a_string_including('Account custom instructions are provided inside <account_custom_instructions> tags.')
      ).and_return(mock_chat)
      expect(mock_chat).to receive(:ask) do |prompt|
        expect(prompt).to include(
          '<account_custom_instructions>',
          'Only transfer to a manager after the user explicitly confirms.',
          '<conversation_context>',
          'User: I cannot log in',
          'Assistant: Did you check your inbox?',
          'User: Yes, still no reset email',
          '<assistant_response_to_classify>',
          'Would you like to talk to support?'
        )
        expect(prompt).not_to include('"role"', '"content"', '<current_user_message>')

        mock_response
      end

      result = service.classify(message_history: message_history, assistant_response: 'Would you like to talk to support?')

      expect(result).to include(
        'action' => 'handoff',
        'action_reason' => 'human_offer_accepted'
      )
    end

    it 'uses the configured Captain model' do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_MODEL', value: 'gpt-4.1-nano')

      expect(RubyLLM).to receive(:chat).with(model: 'gpt-4.1-nano').and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(mock_response)

      result = service.classify(message_history: message_history, assistant_response: 'Would you like to talk to support?')

      expect(result).to include('model' => 'gpt-4.1-nano')
    end

    context 'when the assistant has no custom instructions' do
      before do
        assistant.update!(config: assistant.config.except('instructions'))
      end

      it 'does not add custom-instruction policy to the system prompt' do
        expect(mock_chat).to receive(:with_instructions).with(
          satisfy { |prompt| prompt.exclude?('Account custom instructions are provided') }
        ).and_return(mock_chat)
        allow(mock_chat).to receive(:ask).and_return(mock_response)

        service.classify(message_history: message_history, assistant_response: 'Would you like to talk to support?')
      end
    end
  end
end
