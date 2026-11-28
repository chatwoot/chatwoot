require 'rails_helper'

RSpec.describe Conversations::MessageSummaryLoader do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:agent_bot) { create(:agent_bot, account: account) }

  def create_conversation(agent_last_seen_at: 1.hour.ago)
    create(:conversation, account: account, inbox: inbox, agent_last_seen_at: agent_last_seen_at)
  end

  def create_message(conversation, message_type, created_at: Time.current, sender: conversation.contact)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: message_type, created_at: created_at, sender: sender)
  end

  def attach_image(message)
    attachment = message.attachments.new(account_id: account.id, file_type: :image)
    attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
    attachment.save!
  end

  def queries(&)
    statements = []
    callback = ->(_name, _start, _finish, _id, payload) { statements << payload[:sql] unless payload[:name] == 'SCHEMA' }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
    statements
  end

  def summary_values(summary)
    [summary.last_message, summary.last_non_activity_message, summary.unread_count]
  end

  describe '#perform' do
    let(:without_messages) { create_conversation }
    let(:activity_only) { create_conversation }
    let(:trailing_activities) { create_conversation }
    let(:never_seen) { create_conversation(agent_last_seen_at: nil) }
    let(:many_unread) { create_conversation }
    let(:same_second) { create_conversation }
    let!(:conversations) { [without_messages, activity_only, trailing_activities, never_seen, many_unread, same_second] }

    before do
      create_message(activity_only, :activity, sender: nil)

      create_message(trailing_activities, :incoming, created_at: 2.hours.ago)
      attach_image(create_message(trailing_activities, :outgoing, created_at: 3.minutes.ago, sender: agent))
      create_message(trailing_activities, :activity, created_at: 2.minutes.ago, sender: nil)
      create_message(trailing_activities, :activity, created_at: 1.minute.ago, sender: nil)

      create_message(never_seen, :incoming, created_at: 2.days.ago)
      create_message(never_seen, :incoming, created_at: 1.minute.ago)

      12.times { |index| create_message(many_unread, :incoming, created_at: (12 - index).minutes.ago) }
      attach_image(create_message(many_unread, :outgoing, sender: agent_bot))

      created_at = 1.minute.ago
      create_message(same_second, :activity, created_at: created_at, sender: nil)
      create_message(same_second, :template, created_at: created_at, sender: nil)
    end

    it 'loads the same summary that each conversation loads for itself' do
      expected = conversations.map { |conversation| summary_values(Conversations::MessageSummary.new(conversation)) }

      described_class.new(conversations).perform

      expect(conversations.map { |conversation| summary_values(conversation.message_summary) }).to eq(expected)
      expect(conversations.map { |conversation| conversation.message_summary.unread_count }).to eq([0, 0, 0, 2, 10, 0])
    end

    it 'reads the messages table twice for any number of conversations' do
      statements = queries { described_class.new(conversations).perform }

      expect(statements.count { |sql| sql.include?('FROM "messages"') }).to eq(2)
    end

    it 'leaves nothing to query when the summaries are serialized' do
      # A user sender reads its account user for the current account
      Current.account = account
      loaded = Conversation.where(id: conversations.map(&:id)).includes(:contact_inbox).to_a
      described_class.new(loaded).perform

      statements = queries do
        loaded.each do |conversation|
          summary = conversation.message_summary
          summary.last_message&.push_event_data
          summary.last_non_activity_message&.push_event_data
        end
      end

      expect(statements).to be_empty
    end

    it 'does not query for an empty list' do
      expect(queries { expect(described_class.new([]).perform).to eq([]) }).to be_empty
    end
  end
end
