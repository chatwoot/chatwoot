require 'rails_helper'

RSpec.describe Captain::ConversationCompletionService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:service) { described_class.new(account: account, conversation_display_id: conversation.display_id) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_context) { instance_double(RubyLLM::Context, chat: mock_chat) }

  before do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_API_KEY').update!(value: 'test-key')
    allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
    allow(mock_chat).to receive(:with_instructions)
    allow(mock_chat).to receive(:with_schema).and_return(mock_chat)
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
    allow(Integrations::Openai::KeyValidator).to receive(:valid?).and_return(true)
  end

  describe '#perform' do
    describe 'model routing' do
      let(:mock_response) do
        instance_double(RubyLLM::Message, content: { 'complete' => true, 'reason' => 'Done' }, input_tokens: 10, output_tokens: 5)
      end

      before do
        create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
        allow(mock_chat).to receive(:ask).and_return(mock_response)
      end

      it 'uses the internal GPT-4.1 route on Chatwoot Cloud' do
        allow(ChatwootApp).to receive(:self_hosted_enterprise?).and_return(false)
        InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'gpt-5.1')
        account.enable_features!('captain_integration_v2')
        allow(mock_context).to receive(:chat).with(model: 'gpt-4.1').and_return(mock_chat)

        expect(service.perform).to include(complete: true)
      end

      it 'uses the installation model on self-hosted Enterprise' do
        allow(ChatwootApp).to receive(:self_hosted_enterprise?).and_return(true)
        InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'gpt-5.1')
        allow(mock_context).to receive(:chat).with(model: 'gpt-5.1').and_return(mock_chat)

        expect(service.perform).to include(complete: true)
      end

      it 'uses the account override ahead of the installation model on self-hosted Enterprise' do
        allow(ChatwootApp).to receive(:self_hosted_enterprise?).and_return(true)
        InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'gpt-5.1')
        account.update!(captain_models: { 'conversation_completion' => 'gpt-5.2' })
        allow(mock_context).to receive(:chat).with(model: 'gpt-5.2').and_return(mock_chat)

        expect(service.perform).to include(complete: true)
      end

      it 'falls back to the internal GPT-4.1 route when the self-hosted installation model is blank' do
        allow(ChatwootApp).to receive(:self_hosted_enterprise?).and_return(true)
        InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: '')
        allow(mock_context).to receive(:chat).with(model: 'gpt-4.1').and_return(mock_chat)

        expect(service.perform).to include(complete: true)
      end
    end

    context 'when conversation is complete' do
      let(:mock_response) do
        instance_double(
          RubyLLM::Message,
          content: { 'complete' => true, 'reason' => 'Customer question was fully answered' },
          input_tokens: 100,
          output_tokens: 20
        )
      end

      before do
        create(:message, conversation: conversation, message_type: :incoming, content: 'What are your hours?')
        create(:message, conversation: conversation, message_type: :outgoing, content: 'We are open 9-5 Monday to Friday.')
        create(:message, conversation: conversation, message_type: :incoming, content: 'Thanks!')
        allow(mock_chat).to receive(:ask).and_return(mock_response)
      end

      it 'returns complete: true with reason' do
        result = service.perform

        expect(result[:complete]).to be true
        expect(result[:reason]).to eq('Customer question was fully answered')
      end
    end

    context 'when conversation is incomplete' do
      let(:mock_response) do
        instance_double(
          RubyLLM::Message,
          content: { 'complete' => false, 'reason' => 'Assistant asked for order number but customer did not respond' },
          input_tokens: 100,
          output_tokens: 20
        )
      end

      before do
        create(:message, conversation: conversation, message_type: :incoming, content: 'Where is my order?')
        create(:message, conversation: conversation, message_type: :outgoing, content: 'Can you please share your order number?')
        allow(mock_chat).to receive(:ask).and_return(mock_response)
      end

      it 'returns complete: false with reason' do
        result = service.perform

        expect(result[:complete]).to be false
        expect(result[:reason]).to eq('Assistant asked for order number but customer did not respond')
      end
    end

    context 'when building evaluation context' do
      let(:captain_assistant) { create(:captain_assistant, account: account) }
      let(:mock_response) do
        instance_double(
          RubyLLM::Message,
          content: { 'complete' => false, 'reason' => 'Human follow-up is still pending' },
          input_tokens: 100,
          output_tokens: 20
        )
      end

      it 'includes conversation status and speaker labels' do
        conversation.update!(status: :pending, waiting_since: 2.hours.ago)
        create(:message, conversation: conversation, inbox: inbox, account: account, message_type: :incoming, content: 'I need help with a refund')
        create(
          :message,
          conversation: conversation,
          inbox: inbox,
          account: account,
          message_type: :outgoing,
          sender: captain_assistant,
          content: 'I will transfer this to support for review.'
        )

        expect(mock_chat).to receive(:ask) do |content|
          expect(content).to include(
            'Conversation status: pending',
            'Conversation transcript:',
            'Customer: I need help with a refund',
            'Captain: I will transfer this to support for review.'
          )

          mock_response
        end

        result = service.perform

        expect(result[:complete]).to be false
      end

      it 'includes pending captain handoff evidence in the transcript' do
        conversation.update!(status: :pending)
        create(:message, conversation: conversation, inbox: inbox, account: account, message_type: :incoming, content: 'Please cancel my order')
        create(
          :message,
          conversation: conversation,
          inbox: inbox,
          account: account,
          message_type: :outgoing,
          sender: captain_assistant,
          content: 'I will transfer this to a specialist and they will follow up here.'
        )

        expect(mock_chat).to receive(:ask) do |content|
          expect(content).to include(
            'Conversation status: pending',
            'Captain: I will transfer this to a specialist and they will follow up here.'
          )

          mock_response
        end

        result = service.perform

        expect(result[:complete]).to be false
      end

      it 'reuses computed message content while formatting the transcript' do
        content_for_llm_calls_by_message_id = Hash.new(0)
        allow_any_instance_of(Message).to receive(:content_for_llm).and_wrap_original do |method, *args| # rubocop:disable RSpec/AnyInstance
          content_for_llm_calls_by_message_id[method.receiver.id] += 1
          method.call(*args)
        end

        incoming_message = create(
          :message,
          :with_attachment,
          conversation: conversation,
          inbox: inbox,
          account: account,
          message_type: :incoming,
          content: nil
        )
        outgoing_message = create(
          :message,
          conversation: conversation,
          inbox: inbox,
          account: account,
          message_type: :outgoing,
          sender: captain_assistant,
          content: 'What do you need help with?'
        )

        allow(mock_chat).to receive(:ask).and_return(mock_response)

        service.perform

        expect(content_for_llm_calls_by_message_id).to include(
          incoming_message.id => 1,
          outgoing_message.id => 1
        )
      end
    end

    context 'when conversation has no messages' do
      it 'returns incomplete with appropriate reason' do
        result = service.perform

        expect(result[:complete]).to be false
        expect(result[:reason]).to eq('No messages found')
      end
    end

    context 'when LLM returns non-hash response' do
      let(:mock_response) do
        instance_double(
          RubyLLM::Message,
          content: 'unexpected string response',
          input_tokens: 100,
          output_tokens: 20
        )
      end

      before do
        create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
        allow(mock_chat).to receive(:ask).and_return(mock_response)
      end

      it 'returns incomplete as safe default' do
        result = service.perform

        expect(result[:complete]).to be false
        expect(result[:reason]).to eq('Invalid response format')
      end
    end

    context 'when API call fails' do
      before do
        create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
        allow(mock_chat).to receive(:ask).and_raise(StandardError.new('API Error'))
      end

      it 'returns incomplete with error message' do
        result = service.perform

        expect(result[:complete]).to be false
        expect(result[:reason]).to eq('API Error')
      end
    end

    context 'when captain_tasks feature is disabled' do
      before do
        allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(false)
        create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
      end

      it 'does not evaluate the conversation as complete' do
        result = service.perform

        expect(result[:complete]).not_to be true
      end
    end

    context 'when account has its own OpenAI hook' do
      before do
        create(:message, conversation: conversation, message_type: :incoming, content: 'Hello')
        create(:integrations_hook, :openai, account: account, settings: { 'api_key' => 'customer-own-key' })
      end

      it 'uses the system API key instead of the account hook key' do
        expect(Llm::Config).to receive(:with_api_key).with('test-key', api_base: anything).and_yield(mock_context)
        allow(mock_chat).to receive(:ask).and_return(
          instance_double(RubyLLM::Message, content: { 'complete' => true, 'reason' => 'Done' }, input_tokens: 10, output_tokens: 5)
        )

        service.perform
      end

      it 'does not fall back to the account hook key when no system key exists' do
        InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY').update!(value: nil)

        expect(Llm::Config).not_to receive(:with_api_key)

        result = service.perform

        expect(result[:complete]).to be false
        expect(result[:reason]).to eq(I18n.t('captain.api_key_missing'))
      end
    end

    context 'when customer quota is exhausted' do
      let(:mock_response) do
        instance_double(
          RubyLLM::Message,
          content: { 'complete' => true, 'reason' => 'Customer question was fully answered' },
          input_tokens: 100,
          output_tokens: 20
        )
      end

      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        allow(account).to receive(:usage_limits).and_return(
          {
            agents: ChatwootApp.max_limit,
            inboxes: ChatwootApp.max_limit,
            captain: { responses: { current_available: 0 } }
          }
        )
        create(:message, conversation: conversation, message_type: :incoming, content: 'What are your hours?')
        create(:message, conversation: conversation, message_type: :outgoing, content: 'We are open 9-5 Monday to Friday.')
        allow(mock_chat).to receive(:ask).and_return(mock_response)
      end

      it 'still runs the evaluation bypassing quota check' do
        result = service.perform

        expect(result[:error]).to be_nil
        expect(result[:complete]).to be true
        expect(result[:reason]).to eq('Customer question was fully answered')
      end

      it 'does not increment usage' do
        expect(account).not_to receive(:increment_response_usage)
        service.perform
      end
    end
  end
end
