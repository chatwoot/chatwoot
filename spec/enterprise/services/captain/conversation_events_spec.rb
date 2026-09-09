require 'rails_helper'

RSpec.describe Captain::ConversationEvents do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:timestamp) { Time.zone.now }

  describe '.handed_off' do
    it 'dispatches the handoff event with source and reason category' do
      expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
        Events::Types::CAPTAIN_CONVERSATION_HANDED_OFF,
        timestamp,
        { conversation: conversation, assistant: assistant, source: 'inference', reason_category: :pending_clarification }
      )

      described_class.handed_off(
        conversation: conversation, assistant: assistant, source: 'inference', reason_category: :pending_clarification, at: timestamp
      )
    end
  end

  describe '.resolved' do
    it 'dispatches the resolution event with source' do
      expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
        Events::Types::CAPTAIN_CONVERSATION_RESOLVED,
        timestamp,
        { conversation: conversation, assistant: assistant, source: 'inference' }
      )

      described_class.resolved(conversation: conversation, assistant: assistant, source: 'inference', at: timestamp)
    end
  end

  describe '.response_completed' do
    it 'dispatches the response completed event with the result message' do
      message = create(:message, conversation: conversation, account: account)

      expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
        Events::Types::CAPTAIN_RESPONSE_COMPLETED,
        timestamp,
        { conversation: conversation, assistant: assistant, message: message }
      )

      described_class.response_completed(conversation: conversation, assistant: assistant, message: message, at: timestamp)
    end
  end

  describe 'when dispatch fails' do
    it 'captures the exception instead of raising into the Captain flow' do
      conversation
      assistant
      error = StandardError.new('redis down')
      allow(Rails.configuration.dispatcher).to receive(:dispatch).and_raise(error)
      expect(ChatwootExceptionTracker).to receive(:new)
        .with(error, account: account)
        .and_return(instance_double(ChatwootExceptionTracker, capture_exception: true))

      expect do
        described_class.handed_off(
          conversation: conversation, assistant: assistant, source: 'tool', reason_category: nil, at: timestamp
        )
      end.not_to raise_error
    end
  end

  describe '.response_failed' do
    it 'dispatches the response failed event with the failure reason' do
      expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
        Events::Types::CAPTAIN_RESPONSE_FAILED,
        timestamp,
        { conversation: conversation, assistant: assistant, reason: 'faraday_bad_request_error' }
      )

      described_class.response_failed(conversation: conversation, assistant: assistant, reason: 'faraday_bad_request_error', at: timestamp)
    end
  end
end
