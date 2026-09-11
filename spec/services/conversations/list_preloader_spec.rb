require 'rails_helper'

RSpec.describe Conversations::ListPreloader do
  let(:account) { create(:account) }
  let(:agent) { create(:user, :with_avatar, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_api, account: account)) }
  let(:team) { create(:team, account: account) }
  let(:contact) { create(:contact, :with_avatar, account: account) }
  let(:conversation) do
    create(
      :conversation,
      account: account,
      inbox: inbox,
      contact: contact,
      assignee: agent,
      team: team,
      agent_last_seen_at: 2.hours.ago
    )
  end

  before do
    Current.account = account
    Current.user = agent
  end

  after do
    Current.reset
  end

  describe '#perform' do
    context 'with messages to serialize' do
      let(:same_time) { 10.minutes.ago }
      let!(:unread_messages) do
        create_list(
          :message,
          11,
          account: account,
          inbox: inbox,
          conversation: conversation,
          message_type: :incoming,
          created_at: 1.hour.ago
        )
      end
      let!(:first_same_time_message) do
        create(
          :message,
          :with_attachment,
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: agent,
          message_type: :outgoing,
          created_at: same_time
        )
      end
      let!(:last_non_activity_message) do
        create(
          :message,
          :with_attachment,
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: agent,
          message_type: :outgoing,
          created_at: first_same_time_message.created_at
        )
      end
      let!(:latest_message) do
        create(
          :message,
          :with_attachment,
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: agent,
          message_type: :activity,
          created_at: 5.minutes.ago
        )
      end

      before do
        create(
          :message,
          account: account,
          inbox: inbox,
          conversation: conversation,
          message_type: :incoming,
          created_at: 3.hours.ago
        )
        described_class.new([conversation]).perform
      end

      it 'preloads the messages and capped unread count used by list serialization' do
        expect(conversation.latest_message).to eq(latest_message)
        expect(conversation.last_non_activity_message).to eq(last_non_activity_message)
        expect(conversation.last_incoming_message).to eq(unread_messages.last)
        expect(conversation.unread_incoming_messages_count).to eq(10)
      end

      it 'preloads message attachments, blobs, senders and account users' do
        preloaded_latest_message = conversation.latest_message
        preloaded_non_activity_message = conversation.last_non_activity_message

        expect(preloaded_latest_message.association(:attachments)).to be_loaded
        expect(preloaded_latest_message.attachments.first.file_attachment.association(:blob)).to be_loaded
        expect(preloaded_non_activity_message.association(:attachments)).to be_loaded
        expect(preloaded_non_activity_message.association(:sender)).to be_loaded
        expect(preloaded_non_activity_message.sender.association(:account_users)).to be_loaded
      end
    end

    it 'uses a fixed number of message queries for the conversation page' do
      conversations = create_list(:conversation, 2, account: account, inbox: inbox, agent_last_seen_at: 1.hour.ago)
      conversations.each do |item|
        create_list(:message, 2, account: account, inbox: inbox, conversation: item, message_type: :incoming)
      end
      message_queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        next if payload[:cached] || payload[:name] == 'SCHEMA'

        message_queries << payload[:sql] if payload[:sql].include?('FROM "messages"')
      end

      ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
        described_class.new(conversations).perform
      end

      expect(message_queries.size).to eq(4)
    end

    it 'does not query when there are no conversations' do
      expect(ActiveRecord::Associations::Preloader).not_to receive(:new)
      expect(Message).not_to receive(:all)

      described_class.new([]).perform
    end
  end
end
