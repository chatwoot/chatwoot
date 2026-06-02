# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversations::EventDataPresenter do
  let(:presenter) { described_class.new(conversation) }
  let(:conversation) { create(:conversation) }

  describe '#push_data' do
    let(:expected_data) do
      {
        additional_attributes: {},
        meta: {
          sender: conversation.contact.push_event_data,
          assignee: conversation.assigned_entity&.push_event_data,
          assignee_type: conversation.assignee_type,
          team: conversation.team&.push_event_data,
          hmac_verified: conversation.contact_inbox.hmac_verified
        },
        id: conversation.display_id,
        messages: [],
        labels: [],
        inbox_id: conversation.inbox_id,
        status: conversation.status,
        contact_inbox: conversation.contact_inbox,
        can_reply: conversation.can_reply?,
        channel: conversation.inbox.channel_type,
        timestamp: conversation.last_activity_at.to_i,
        snoozed_until: conversation.snoozed_until,
        custom_attributes: conversation.custom_attributes,
        first_reply_created_at: nil,
        contact_last_seen_at: conversation.contact_last_seen_at.to_i,
        agent_last_seen_at: conversation.agent_last_seen_at.to_i,
        created_at: conversation.created_at.to_i,
        updated_at: conversation.updated_at.to_f,
        waiting_since: conversation.waiting_since.to_i,
        priority: nil,
        unread_count: 0
      }
    end

    it 'returns push event payload' do
      # the exceptions are the values that would be added in enterprise edition.
      expect(presenter.push_data.except(:applied_sla, :sla_events)).to include(expected_data)
    end
  end

  describe '#webhook_data' do
    it 'normalizes hard-break backslashes in message content' do
      message = create(:message, conversation: conversation, account: conversation.account,
                                 message_type: :outgoing, content: "Hello\\\nWorld")
      data = presenter.webhook_data
      webhook_message = data[:messages].first

      expect(webhook_message).to be_present
      expect(webhook_message[:content]).to eq("Hello\nWorld")
      expect(webhook_message[:id]).to eq(message.id)
    end

    it 'preserves normal newlines in message content' do
      create(:message, conversation: conversation, account: conversation.account,
                       message_type: :outgoing, content: "Line one\n\nLine two")
      webhook_message = presenter.webhook_data[:messages].first

      expect(webhook_message[:content]).to eq("Line one\n\nLine two")
    end

    it 'returns empty messages when conversation has no chat messages' do
      expect(presenter.webhook_data[:messages]).to eq([])
    end
  end
end
