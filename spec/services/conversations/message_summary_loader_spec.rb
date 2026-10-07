require 'rails_helper'

RSpec.describe Conversations::MessageSummaryLoader do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, agent_last_seen_at: 1.hour.ago) }
  let(:message_attributes) { { account: account, inbox: inbox, conversation: conversation } }

  describe '#perform' do
    it 'returns the given conversations' do
      conversations = [conversation]

      expect(described_class.new(conversations).perform).to equal(conversations)
    end

    it 'returns an empty list as it is' do
      expect(described_class.new([]).perform).to eq([])
    end

    context 'when loading the latest message' do
      it 'picks the most recent message' do
        create(:message, **message_attributes, created_at: 10.minutes.ago)
        latest = create(:message, **message_attributes, created_at: 1.minute.ago)

        described_class.new([conversation]).perform

        expect(conversation.message_summary.last_message_data[:id]).to eq(latest.id)
      end

      it 'breaks created_at ties with the higher id' do
        created_at = 5.minutes.ago
        create(:message, **message_attributes, created_at: created_at)
        second = create(:message, **message_attributes, created_at: created_at)

        described_class.new([conversation]).perform

        expect(conversation.message_summary.last_message_data[:id]).to eq(second.id)
      end

      it 'has no message data for a conversation without messages' do
        described_class.new([conversation]).perform

        summary = conversation.message_summary
        expect(summary.last_message_data).to be_nil
        expect(summary.last_non_activity_message_data).to be_nil
        expect(summary.unread_count).to eq(0)
      end
    end

    context 'when loading the latest non-activity message' do
      it 'skips activity messages' do
        reply = create(:message, **message_attributes, message_type: :outgoing, created_at: 10.minutes.ago)
        activity = create(:message, **message_attributes, message_type: :activity, created_at: 1.minute.ago)

        described_class.new([conversation]).perform

        summary = conversation.message_summary
        expect(summary.last_message_data[:id]).to eq(activity.id)
        expect(summary.last_non_activity_message_data[:id]).to eq(reply.id)
      end

      it 'serializes the message once when it is also the latest message' do
        create(:message, **message_attributes, created_at: 1.minute.ago)

        described_class.new([conversation]).perform

        summary = conversation.message_summary
        expect(summary.last_non_activity_message_data).to equal(summary.last_message_data)
      end
    end

    context 'when counting unread messages' do
      it 'counts incoming messages created after the agent last saw the conversation' do
        create(:message, **message_attributes, created_at: 2.hours.ago)
        create_list(:message, 2, **message_attributes, created_at: 10.minutes.ago)
        create(:message, **message_attributes, message_type: :outgoing, created_at: 5.minutes.ago)

        described_class.new([conversation]).perform

        summary = conversation.message_summary
        expect(summary.unread_count).to eq(2)
        expect(summary.last_message_data[:conversation][:unread_count]).to eq(2)
      end

      it 'counts every incoming message when the agent has not seen the conversation' do
        conversation.update!(agent_last_seen_at: nil)
        create_list(:message, 3, **message_attributes, created_at: 2.hours.ago)

        described_class.new([conversation]).perform

        expect(conversation.message_summary.unread_count).to eq(3)
      end

      it 'stops counting at the limit' do
        create_list(:message, Conversation::UNREAD_INCOMING_MESSAGES_LIMIT + 2, **message_attributes, created_at: 10.minutes.ago)

        described_class.new([conversation]).perform

        expect(conversation.message_summary.unread_count).to eq(Conversation::UNREAD_INCOMING_MESSAGES_LIMIT)
      end
    end

    context 'when the latest messages have different sender types' do
      let(:bot_conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:senderless_conversation) { create(:conversation, account: account, inbox: inbox) }

      it 'loads every summary without a sender type that lacks account users failing the preload' do
        contact_message = create(:message, **message_attributes, sender: create(:contact, account: account))
        bot_message = create(:message, **message_attributes, conversation: bot_conversation, message_type: :outgoing,
                                                             sender: create(:agent_bot, account: account))
        senderless_message = create(:message, :bot_message, **message_attributes, conversation: senderless_conversation)

        described_class.new([conversation, bot_conversation, senderless_conversation]).perform

        expect(conversation.message_summary.last_message_data[:id]).to eq(contact_message.id)
        expect(bot_conversation.message_summary.last_message_data[:id]).to eq(bot_message.id)
        expect(senderless_conversation.message_summary.last_message_data[:id]).to eq(senderless_message.id)
      end
    end

    context 'with several conversations' do
      let(:other_conversation) { create(:conversation, account: account, inbox: inbox, agent_last_seen_at: 1.hour.ago) }

      it 'loads every summary with one conversation query and one message query' do
        message = create(:message, **message_attributes, created_at: 2.minutes.ago)
        other_message = create(:message, **message_attributes, conversation: other_conversation, created_at: 1.minute.ago)
        queries = []
        record_query = ->(*, payload) { queries << payload[:name] }

        ActiveSupport::Notifications.subscribed(record_query, 'sql.active_record') do
          described_class.new([conversation, other_conversation]).perform
        end

        expect(queries.count('Conversation Pluck')).to eq(1)
        expect(queries.count('Message Load')).to eq(1)
        expect(conversation.message_summary.last_message_data[:id]).to eq(message.id)
        expect(other_conversation.message_summary.last_message_data[:id]).to eq(other_message.id)
      end
    end
  end
end
