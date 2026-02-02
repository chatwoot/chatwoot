require 'rails_helper'

RSpec.describe Captain::ReplySuggestionService do
  subject(:service) { described_class.new(account: account, conversation_display_id: conversation.display_id, user: agent) }

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, name: 'Jane Smith') }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:captured_messages) { [] }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    create(:message, conversation: conversation, message_type: :incoming, content: 'I need help')
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)

    mock_response = instance_double(RubyLLM::Message, content: 'Sure, I can help!', input_tokens: 50, output_tokens: 20)
    mock_chat = instance_double(RubyLLM::Chat)
    mock_context = instance_double(RubyLLM::Context, chat: mock_chat)

    allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
    allow(mock_chat).to receive(:with_tool).and_return(mock_chat)
    allow(mock_chat).to receive(:on_end_message).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions) { |msg| captured_messages << { role: 'system', content: msg } }
    allow(mock_chat).to receive(:add_message) { |args| captured_messages << args }
    allow(mock_chat).to receive(:ask) do |msg|
      captured_messages << { role: 'user', content: msg }
      mock_response
    end
  end

  describe '#perform' do
    it 'returns the suggested reply' do
      result = service.perform

      expect(result[:message]).to eq('Sure, I can help!')
    end

    it 'formats conversation using LlmFormatter' do
      service.perform

      user_message = captured_messages.find { |m| m[:role] == 'user' }
      expect(user_message[:content]).to include('Message History:')
      expect(user_message[:content]).to include('User: I need help')
    end

    context 'with chat channel' do
      it 'uses chat-specific instructions' do
        service.perform

        system_prompt = captured_messages.find { |m| m[:role] == 'system' }[:content]
        expect(system_prompt).to include('CHAT conversation')
        expect(system_prompt).to include('brief, conversational')
        expect(system_prompt).not_to include('EMAIL conversation')
      end
    end

    context 'with email channel' do
      let(:email_channel) { create(:channel_email, account: account) }
      let(:inbox) { create(:inbox, account: account, channel: email_channel) }

      it 'uses email-specific instructions' do
        service.perform

        system_prompt = captured_messages.find { |m| m[:role] == 'system' }[:content]
        expect(system_prompt).to include('EMAIL conversation')
        expect(system_prompt).to include('professional email')
        expect(system_prompt).not_to include('CHAT conversation')
      end

      context 'when agent has a signature' do
        let(:agent) { create(:user, account: account, name: 'Jane Smith', message_signature: "Best,\nJane Smith") }

        it 'includes the signature in the prompt' do
          service.perform

          system_prompt = captured_messages.find { |m| m[:role] == 'system' }[:content]
          expect(system_prompt).to include("Best,\nJane Smith")
        end
      end

      context 'when agent has no signature' do
        let(:agent) { create(:user, account: account, name: 'Jane Smith', message_signature: nil) }

        it 'falls back to agent name for sign-off' do
          service.perform

          system_prompt = captured_messages.find { |m| m[:role] == 'system' }[:content]
          expect(system_prompt).to include("sign-off using the agent's name: Jane Smith")
        end
      end
    end
  end
end
