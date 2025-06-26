require 'rails_helper'

RSpec.describe Captain::Copilot::ChatService do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:mock_openai_client) { instance_double(OpenAI::Client) }
  let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user) }
  let!(:copilot_message) do
    create(
      :captain_copilot_message, account: account, copilot_thread: copilot_thread
    )
  end
  let(:previous_history) { [{ role: copilot_message.message_type, content: copilot_message.message['content'] }] }

  let(:config) do
    { user_id: user.id, copilot_thread_id: copilot_thread.id, conversation_id: conversation.display_id }
  end

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(OpenAI::Client).to receive(:new).and_return(mock_openai_client)
    allow(mock_openai_client).to receive(:chat).and_return({
      choices: [{ message: { content: '{ "content": "Hey" }' } }]
    }.with_indifferent_access)
  end

  describe '#initialize' do
    it 'sets up the service with correct instance variables' do
      service = described_class.new(assistant, config)

      expect(service.assistant).to eq(assistant)
      expect(service.account).to eq(account)
      expect(service.user).to eq(user)
      expect(service.copilot_thread).to eq(copilot_thread)
      expect(service.previous_history).to eq(previous_history)
    end

    it 'builds messages with system message and account context' do
      service = described_class.new(assistant, config)
      messages = service.messages

      expect(messages.first[:role]).to eq('system')
      expect(messages.second[:role]).to eq('system')
      expect(messages.second[:content]).to include(account.id.to_s)
    end
  end

  describe '#generate_response' do
    let(:service) { described_class.new(assistant, config) }

    it 'adds user input to messages when present' do
      expect do
        service.generate_response('Hello')
      end.to(change { service.messages.count }.by(1))

      last_message = service.messages.last
      expect(last_message[:role]).to eq('user')
      expect(last_message[:content]).to eq('Hello')
    end

    it 'does not add user input to messages when blank' do
      expect do
        service.generate_response('')
      end.not_to(change { service.messages.count })
    end

    it 'returns the response from request_chat_completion' do
      expect(service.generate_response('Hello')).to eq({ 'content' => 'Hey' })
    end

    context 'when response contains tool calls' do
      before do
        allow(mock_openai_client).to receive(:chat).and_return(
          {
            choices: [{ message: { 'tool_calls' => tool_calls } }]
          }.with_indifferent_access,
          {
            choices: [{ message: { content: '{ "content": "Tool response processed" }' } }]
          }.with_indifferent_access
        )
      end

      context 'when tool call is valid' do
        let(:tool_calls) do
          [{
            'id' => 'call_123',
            'function' => {
              'name' => 'get_conversation',
              'arguments' => "{ \"conversation_id\": #{conversation.display_id} }"
            }
          }]
        end

        it 'processes tool calls and appends them to messages' do
          result = service.generate_response("Find conversation #{conversation.id}")

          expect(result).to eq({ 'content' => 'Tool response processed' })
          expect(service.messages).to include(
            { role: 'assistant', tool_calls: tool_calls }
          )
          expect(service.messages).to include(
            {
              role: 'tool', tool_call_id: 'call_123', content: conversation.to_llm_text
            }
          )

          expect(result).to eq({ 'content' => 'Tool response processed' })
        end
      end

      context 'when tool call is invalid' do
        let(:tool_calls) do
          [{
            'id' => 'call_123',
            'function' => {
              'name' => 'get_settings',
              'arguments' => '{}'
            }
          }]
        end

        it 'handles invalid tool calls' do
          result = service.generate_response('Find settings')

          expect(result).to eq({ 'content' => 'Tool response processed' })
          expect(service.messages).to include(
            {
              role: 'assistant', tool_calls: tool_calls
            }
          )
          expect(service.messages).to include(
            {
              role: 'tool',
              tool_call_id: 'call_123',
              content: 'Tool not available'
            }
          )
        end
      end
    end
  end

  describe '#setup_user' do
    it 'sets user when user_id is present in config' do
      service = described_class.new(assistant, { user_id: user.id })
      expect(service.user).to eq(user)
    end

    it 'does not set user when user_id is not present in config' do
      service = described_class.new(assistant, {})
      expect(service.user).to be_nil
    end
  end

  describe '#setup_message_history' do
    context 'when copilot_thread_id is present' do
      it 'finds the copilot thread and sets previous history from it' do
        service = described_class.new(assistant, { copilot_thread_id: copilot_thread.id })

        expect(service.copilot_thread).to eq(copilot_thread)
        expect(service.previous_history).to eq previous_history
      end
    end

    context 'when copilot_thread_id is not present' do
      it 'uses previous_history from config if present' do
        custom_history = [{ role: 'user', content: 'Custom message' }]
        service = described_class.new(assistant, { previous_history: custom_history })

        expect(service.copilot_thread).to be_nil
        expect(service.previous_history).to eq(custom_history)
      end

      it 'uses empty array if previous_history is not present in config' do
        service = described_class.new(assistant, {})

        expect(service.copilot_thread).to be_nil
        expect(service.previous_history).to eq([])
      end
    end
  end

  describe '#build_messages' do
    it 'includes system message and account context' do
      service = described_class.new(assistant, {})
      messages = service.messages

      expect(messages.first[:role]).to eq('system')
      expect(messages.second[:role]).to eq('system')
      expect(messages.second[:content]).to include(account.id.to_s)
    end

    it 'includes previous history when present' do
      custom_history = [{ role: 'user', content: 'Custom message' }]
      service = described_class.new(assistant, { previous_history: custom_history })
      messages = service.messages

      expect(messages.count).to be >= 3
      expect(messages.any? { |m| m[:content] == 'Custom message' }).to be true
    end

    it 'includes current viewing history when conversation_id is present' do
      service = described_class.new(assistant, { conversation_id: conversation.display_id })
      messages = service.messages

      viewing_history = messages.find { |m| m[:content].include?('You are currently viewing the conversation') }
      expect(viewing_history).not_to be_nil
      expect(viewing_history[:content]).to include(conversation.display_id.to_s)
      expect(viewing_history[:content]).to include(contact.id.to_s)
    end
  end

  describe '#persist_message' do
    context 'when copilot_thread is present' do
      it 'creates a copilot message' do
        allow(mock_openai_client).to receive(:chat).and_return({
          choices: [{ message: { content: '{ "content": "Hey" }' } }]
        }.with_indifferent_access)

        expect do
          described_class.new(assistant, { copilot_thread_id: copilot_thread.id }).generate_response('Hello')
        end.to change(CopilotMessage, :count).by(1)

        last_message = CopilotMessage.last
        expect(last_message.message_type).to eq('assistant')
        expect(last_message.message['content']).to eq('Hey')
      end
    end

    context 'when copilot_thread is not present' do
      it 'does not create a copilot message' do
        allow(mock_openai_client).to receive(:chat).and_return({
          choices: [{ message: { content: '{ "content": "Hey" }' } }]
        }.with_indifferent_access)

        expect do
          described_class.new(assistant, {}).generate_response('Hello')
        end.not_to(change(CopilotMessage, :count))
      end
    end
  end
end
