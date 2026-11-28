require 'rails_helper'

RSpec.describe Conversations::MessageSummary do
  subject(:message_summary) { described_class.new(conversation) }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, agent_last_seen_at: agent_last_seen_at) }
  let(:agent_last_seen_at) { 1.hour.ago }

  def create_message(message_type, created_at: Time.current)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: message_type, created_at: created_at)
  end

  context 'when the conversation has no messages' do
    it 'has no messages and no unread count' do
      expect(message_summary.last_message).to be_nil
      expect(message_summary.last_non_activity_message).to be_nil
      expect(message_summary.unread_count).to eq(0)
    end
  end

  describe '#last_message' do
    it 'returns the newest message of any type' do
      create_message(:incoming, created_at: 2.minutes.ago)
      activity = create_message(:activity, created_at: 1.minute.ago)

      expect(message_summary.last_message).to eq(activity)
    end

    it 'returns the higher id when two messages share a created_at' do
      created_at = 1.minute.ago
      create_message(:activity, created_at: created_at)
      survey = create_message(:template, created_at: created_at)

      expect(message_summary.last_message).to eq(survey)
    end
  end

  describe '#last_non_activity_message' do
    it 'skips the activity messages that follow it' do
      create_message(:incoming, created_at: 3.minutes.ago)
      reply = create_message(:outgoing, created_at: 2.minutes.ago)
      create_message(:activity, created_at: 1.minute.ago)

      expect(message_summary.last_non_activity_message).to eq(reply)
    end
  end

  describe '#unread_count' do
    it 'counts the incoming messages created after the agent last saw the conversation' do
      create_message(:incoming, created_at: 2.hours.ago)
      create_message(:incoming)
      create_message(:outgoing)

      expect(message_summary.unread_count).to eq(1)
    end

    context 'when no agent has seen the conversation' do
      let(:agent_last_seen_at) { nil }

      it 'counts every incoming message' do
        create_message(:incoming, created_at: 2.hours.ago)
        create_message(:incoming)

        expect(message_summary.unread_count).to eq(2)
      end
    end

    it 'stops counting at 10' do
      create_list(:message, 11, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)

      expect(message_summary.unread_count).to eq(10)
    end
  end
end
