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
          assignee: conversation.assignee,
          team: conversation.team,
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
end
