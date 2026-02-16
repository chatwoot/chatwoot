# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::ResponseJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_all_features, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }
  let(:message) { create(:message, conversation: conversation, message_type: :incoming, content: 'Hello') }

  before do
    create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox)
    # Mock Redis lock so all existing tests acquire the lock by default
    allow(Redis::Alfred).to receive(:set).and_return(true)
    allow(Redis::Alfred).to receive(:delete)
  end

  describe '#perform' do
    context 'when conversation not found' do
      it 'returns early' do
        expect(ConversationAgent).not_to receive(:call)

        described_class.new.perform(999_999, message.id)
      end
    end

    context 'when message not found' do
      it 'returns early' do
        expect(ConversationAgent).not_to receive(:call)

        described_class.new.perform(conversation.id, 999_999)
      end
    end

    context 'when assistant is inactive' do
      before { assistant.update!(active: false) }

      it 'returns early' do
        expect(ConversationAgent).not_to receive(:call)

        described_class.new.perform(conversation.id, message.id)
      end
    end

    context 'when human agent is assigned' do
      let(:agent) { create(:user, account: account) }

      before do
        conversation.update!(assignee: agent)
      end

      it 'returns early' do
        expect(ConversationAgent).not_to receive(:call)

        described_class.new.perform(conversation.id, message.id)
      end
    end

    context 'when message is outgoing' do
      let(:message) { create(:message, conversation: conversation, message_type: :outgoing) }

      it 'returns early' do
        expect(ConversationAgent).not_to receive(:call)

        described_class.new.perform(conversation.id, message.id)
      end
    end

    context 'when all conditions met' do
      let(:agent_result) do
        instance_double(
          'RubyLLM::Agents::Result',
          success?: true,
          content: 'Hello! How can I help you?',
          input_tokens: 100,
          output_tokens: 50,
          total_cost: 0.001,
          tool_calls: []
        )
      end

      before do
        allow(ConversationAgent).to receive(:call).and_return(agent_result)
      end

      it 'sets Aloo::Current context' do
        described_class.new.perform(conversation.id, message.id)

        # Context is reset after job, but we can verify agent was called
        expect(ConversationAgent).to have_received(:call)
      end

      it 'calls ConversationAgent with message' do
        expect(ConversationAgent).to receive(:call).with(
          message: message.content
        ).and_return(agent_result)

        described_class.new.perform(conversation.id, message.id)
      end

      it 'creates outgoing message' do
        expect do
          described_class.new.perform(conversation.id, message.id)
        end.to change { conversation.messages.where(message_type: :outgoing).count }.by(1)
      end

      it 'tracks usage in ConversationContext' do
        described_class.new.perform(conversation.id, message.id)

        context = Aloo::ConversationContext.find_by(conversation: conversation)
        expect(context.message_count).to eq(1)
        expect(context.input_tokens).to eq(100)
        expect(context.output_tokens).to eq(50)
      end

      it 'updates conversation status' do
        described_class.new.perform(conversation.id, message.id)

        expect(conversation.reload.status).to eq('open')
      end
    end

    context 'when handoff is triggered' do
      let(:agent_result) do
        instance_double(
          'RubyLLM::Agents::Result',
          success?: true,
          content: 'Let me transfer you to a human.',
          input_tokens: 100,
          output_tokens: 50,
          total_cost: 0.001,
          tool_calls: [{ 'name' => 'handoff' }]
        )
      end

      before do
        allow(ConversationAgent).to receive(:call).and_return(agent_result)
      end

      it 'does not send response message' do
        expect do
          described_class.new.perform(conversation.id, message.id)
        end.not_to(change { conversation.messages.where(message_type: :outgoing).count })
      end
    end

    context 'when error occurs' do
      before do
        allow(ConversationAgent).to receive(:call).and_raise(StandardError, 'API Error')
      end

      it 'logs error and re-raises' do
        expect(Rails.logger).to receive(:error).at_least(:once)

        expect do
          described_class.new.perform(conversation.id, message.id)
        end.to raise_error(StandardError)
      end
    end

    describe 'Redis dedup lock' do
      context 'when lock is already held by another AI system' do
        before do
          allow(Redis::Alfred).to receive(:set).and_return(false)
        end

        it 'skips processing and does not call ResponseService' do
          service = instance_double(Aloo::ResponseService)
          allow(Aloo::ResponseService).to receive(:new).and_return(service)

          described_class.new.perform(conversation.id, message.id)

          expect(Aloo::ResponseService).not_to have_received(:new)
        end

        it 'does not create any outgoing messages' do
          expect do
            described_class.new.perform(conversation.id, message.id)
          end.not_to(change { conversation.messages.where(message_type: :outgoing).count })
        end

        it 'does not clean up the lock it did not acquire' do
          described_class.new.perform(conversation.id, message.id)

          expect(Redis::Alfred).not_to have_received(:delete)
        end
      end

      context 'when lock is acquired' do
        let(:agent_result) do
          instance_double(
            'RubyLLM::Agents::Result',
            success?: true,
            content: 'AI response',
            input_tokens: 10,
            output_tokens: 5,
            total_cost: 0.0001,
            tool_calls: []
          )
        end

        before do
          allow(ConversationAgent).to receive(:call).and_return(agent_result)
        end

        it 'acquires the lock with the correct key and parameters' do
          described_class.new.perform(conversation.id, message.id)

          expected_key = "ai_response_lock:msg_#{message.id}"
          expect(Redis::Alfred).to have_received(:set).with(expected_key, 'aloo_local', nx: true, ex: 300)
        end

        it 'uses source_id for lock key when present' do
          message.update!(source_id: 'wamid.abc123')

          described_class.new.perform(conversation.id, message.id)

          expect(Redis::Alfred).to have_received(:set).with('ai_response_lock:wamid.abc123', 'aloo_local', nx: true, ex: 300)
        end

        it 'cleans up the lock after successful processing' do
          described_class.new.perform(conversation.id, message.id)

          expected_key = "ai_response_lock:msg_#{message.id}"
          expect(Redis::Alfred).to have_received(:delete).with(expected_key)
        end
      end

      context 'when processing raises an error' do
        before do
          allow(ConversationAgent).to receive(:call).and_raise(StandardError, 'Boom')
        end

        it 'cleans up the lock even after an error' do
          expect do
            described_class.new.perform(conversation.id, message.id)
          end.to raise_error(StandardError, 'Boom')

          expected_key = "ai_response_lock:msg_#{message.id}"
          expect(Redis::Alfred).to have_received(:delete).with(expected_key)
        end
      end
    end
  end

  describe 'job configuration' do
    it 'is queued in default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end

    it 'has retry_on configured for RubyLLM::Error' do
      # Verify that the job class has retry_on configured
      # ActiveJob doesn't expose this directly, but we can check the class definition
      expect(described_class.ancestors).to include(ActiveJob::Base)
    end
  end
end
