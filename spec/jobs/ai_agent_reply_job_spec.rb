# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AiAgentReplyJob do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:ai_agent) { create(:ai_agent, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, conversation: conversation, account: account) }

  describe 'retry configuration' do
    before do
      allow(Agent::Executor).to receive(:new).and_raise(Llm::Client::RateLimitError, 'rate limited')
      allow(ChatwootExceptionTracker).to receive_message_chain(:new, :capture_exception)
    end

    it 'retries on Llm::Client::RateLimitError' do
      assert_enqueued_jobs 1, only: described_class do
        described_class.perform_now(message_id: message.id, ai_agent_id: ai_agent.id, account_id: account.id)
      end
    end

    it 'retries on Llm::Client::TimeoutError' do
      allow(Agent::Executor).to receive(:new).and_raise(Llm::Client::TimeoutError, 'timed out')

      assert_enqueued_jobs 1, only: described_class do
        described_class.perform_now(message_id: message.id, ai_agent_id: ai_agent.id, account_id: account.id)
      end
    end

    it 'discards on ActiveRecord::RecordNotFound' do
      allow(Message).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

      expect do
        described_class.perform_now(message_id: 0, ai_agent_id: ai_agent.id, account_id: account.id)
      end.not_to raise_error
    end
  end

  describe '#perform' do
    let(:executor_result) do
      double('ExecutorResult', reply: 'Hello! How can I help?', handed_off?: false,
                               usage: { 'prompt_tokens' => 100, 'completion_tokens' => 50 })
    end

    before do
      allow(Agent::Executor).to receive(:new).and_return(double(execute: executor_result))
    end

    it 'creates an outgoing message with the AI reply' do
      expect do
        described_class.perform_now(message_id: message.id, ai_agent_id: ai_agent.id, account_id: account.id)
      end.to change { conversation.messages.outgoing.count }.by(1)
    end

    it 'marks the message as ai_generated' do
      described_class.perform_now(message_id: message.id, ai_agent_id: ai_agent.id, account_id: account.id)
      reply = conversation.messages.outgoing.last
      expect(reply.content_attributes['ai_generated']).to be true
    end

    context 'when the agent hands off' do
      let(:handoff_result) do
        double('ExecutorResult', reply: nil, handed_off?: true, usage: nil)
      end

      before do
        allow(Agent::Executor).to receive(:new).and_return(double(execute: handoff_result))
      end

      it 'does not create an outgoing message' do
        expect do
          described_class.perform_now(message_id: message.id, ai_agent_id: ai_agent.id, account_id: account.id)
        end.not_to change { conversation.messages.outgoing.count }
      end
    end

    context 'when an error occurs' do
      before do
        allow(Agent::Executor).to receive(:new).and_raise(StandardError, 'Something went wrong')
        allow(ChatwootExceptionTracker).to receive_message_chain(:new, :capture_exception)
      end

      it 'tracks the exception and re-raises' do
        expect do
          described_class.perform_now(message_id: message.id, ai_agent_id: ai_agent.id, account_id: account.id)
        end.to raise_error(StandardError, 'Something went wrong')
      end
    end
  end
end
