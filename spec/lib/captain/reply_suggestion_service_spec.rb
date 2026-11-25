require 'rails_helper'

RSpec.describe Captain::ReplySuggestionService do
  subject(:service) { described_class.new(account: account, conversation_display_id: conversation.display_id, user: agent) }

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, name: 'Jane Smith') }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:captured_messages) { [] }
  let(:model_reply) { 'Sure, I can help!' }
  let(:model_answer) { nil }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }

  before do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_API_KEY').update!(value: 'test-key')
    create(:message, conversation: conversation, message_type: :incoming, content: 'I need help', created_at: 3.hours.ago)
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)

    mock_response = instance_double(RubyLLM::Message, content: model_reply, parsed: model_answer, tokens: RubyLLM::Tokens.new(input: 50, output: 20))
    mock_context = instance_double(RubyLLM::Context, chat: mock_chat)

    allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
    allow(mock_chat).to receive(:with_tools).and_return(mock_chat)
    allow(mock_chat).to receive(:after_message).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions) { |msg| captured_messages << { role: 'system', content: msg } }
    allow(mock_chat).to receive(:with_thinking).and_return(mock_chat)
    allow(mock_chat).to receive(:with_schema).and_return(mock_chat)
    allow(mock_chat).to receive(:add_message) { |args| captured_messages << args }
    allow(mock_chat).to receive(:ask) do |msg|
      captured_messages << { role: 'user', content: msg }
      mock_response
    end
  end

  describe '#perform' do
    it 'routes through the editor feature' do
      expect(Llm::FeatureRouter).to receive(:resolve).with(feature: 'editor', account: account).and_call_original

      service.perform
    end

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

    it 'leaves message times out of the transcript and asks for plain text' do
      service.perform

      expect(mock_chat).not_to have_received(:with_schema)

      user_message = captured_messages.find { |m| m[:role] == 'user' }[:content]
      expect(user_message).not_to include('Current Time:')
      expect(user_message).to include("User: I need help\n")
    end

    context 'when the account has the captain_agent_reply_draft feature' do
      let(:system_prompt) { captured_messages.find { |m| m[:role] == 'system' }[:content] }
      let(:model_answer) { { 'reply_needed' => true, 'reply' => 'Sure, I can help!', 'note_for_agent' => 'Check the plan first.' } }
      let(:transcript) { captured_messages.find { |m| m[:role] == 'user' }[:content] }

      before do
        account.update!(name: 'Acme Support Co')
        account.enable_features!(described_class::AGENT_REPLY_FEATURE)
      end

      it 'drafts as an agent of the business, with message times in the transcript' do
        service.perform

        expect(system_prompt).to include('support agent at Acme Support Co')
        expect(system_prompt).to include('[AGENT:')
        expect(transcript).to include('Current Time:')
        expect(transcript).to include('Latest Message: from User, 3 hours ago')
        expect(transcript).to include('Customer Last Wrote: 3 hours ago')
        expect(transcript).to match(/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2} UTC\] User: I need help/)
      end

      it 'asks for a structured answer and gives the agent only the reply' do
        result = service.perform

        expect(mock_chat).to have_received(:with_schema).with(Captain::AgentReplySchema)
        expect(result[:message]).to eq('Sure, I can help!')
        expect(result[:follow_up_context][:last_response]).to eq('Sure, I can help!')
      end

      it 'includes the canned responses, newest first' do
        create(:canned_response, account: account, short_code: 'refund', content: 'Refunds take 5 days.', updated_at: 2.days.ago)
        create(:canned_response, account: account, short_code: 'trial', content: 'Your trial code is X.', updated_at: 1.day.ago)

        service.perform

        expect(system_prompt).to include("- trial: Your trial code is X.\n- refund: Refunds take 5 days.")
      end

      it 'leaves out canned responses past the size limit and logs it' do
        stub_const("#{described_class}::CANNED_RESPONSES_CHARACTER_LIMIT", 30)
        create(:canned_response, account: account, short_code: 'old', content: 'Older reply', updated_at: 2.days.ago)
        create(:canned_response, account: account, short_code: 'new', content: 'Newer reply', updated_at: 1.day.ago)
        allow(Rails.logger).to receive(:info).and_call_original

        service.perform

        expect(system_prompt).to include('- new: Newer reply')
        expect(system_prompt).not_to include('Older reply')
        expect(Rails.logger).to have_received(:info).with(/1 of 2 canned responses fit in 30 characters/)
      end

      it 'reads canned responses in batches, newest first, and stops at the size limit' do
        stub_const("#{described_class}::CANNED_RESPONSES_BATCH_SIZE", 1)
        stub_const("#{described_class}::CANNED_RESPONSES_CHARACTER_LIMIT", 40)
        create(:canned_response, account: account, short_code: 'oldest', content: 'Oldest reply', updated_at: 3.days.ago)
        create(:canned_response, account: account, short_code: 'older', content: 'Older reply', updated_at: 2.days.ago)
        create(:canned_response, account: account, short_code: 'new', content: 'Newer reply', updated_at: 1.day.ago)
        queries = []
        callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('"canned_responses"."content"') }

        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { service.perform }

        expect(system_prompt).to include("- new: Newer reply\n- older: Older reply")
        expect(system_prompt).not_to include('Oldest reply')
        expect(queries.size).to eq(3)
      end

      context 'when an agent sent the latest message' do
        let(:model_answer) { { 'reply_needed' => false, 'reply' => '', 'note_for_agent' => 'You already answered the customer.' } }

        before do
          create(:message, conversation: conversation, message_type: :outgoing, sender: agent, content: 'Done, it is enabled.',
                           created_at: 10.minutes.ago)
        end

        it 'tells the model the agent spoke last and returns no draft with the reason' do
          result = service.perform

          expect(transcript).to include('Latest Message: from Support Agent, 10 minutes ago')
          expect(result).to eq(message: nil, no_reply_reason: 'You already answered the customer.')
        end
      end
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
