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
        updated_at: Conversation.find(conversation.id).updated_at.to_f,
        waiting_since: conversation.waiting_since.to_i,
        priority: nil,
        unread_count: 0
      }
    end

    it 'returns push event payload' do
      # the exceptions are the values that would be added in enterprise edition.
      expect(presenter.push_data.except(:applied_sla, :sla_events)).to include(expected_data)
    end

    # The conversation that was just saved keeps the clock's full resolution (nanoseconds on Linux)
    # while Postgres keeps microseconds; the version a consumer compares must be the stored one.
    it 'ships the updated_at the database stores, not the sub-microsecond clock of the record in memory' do
      conversation.update!(updated_at: Time.zone.at(1_791_823_361, 121_236_812, :nsec))

      stored = Conversation.find(conversation.id).updated_at.to_f
      expect(stored).to eq(Time.zone.at(1_791_823_361, 121_236, :usec).to_f)
      expect(presenter.push_data[:updated_at]).to eq(stored)
    end
  end

  describe '#widget_data' do
    it 'returns only the conversation id and state' do
      expect(presenter.widget_data).to eq(
        id: conversation.display_id,
        inbox_id: conversation.inbox_id,
        contact_last_seen_at: conversation.contact_last_seen_at.to_i,
        status: conversation.status
      )
    end
  end

  describe '#webhook_data' do
    it 'includes account details for webhook consumers' do
      expect(presenter.webhook_data[:account]).to eq(conversation.account.webhook_data)
    end

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

  describe '#push_data messages' do
    # `push_data` is broadcast to the contact as well (ActionCableListener
    # bundles `user_tokens + contact_inbox_tokens` for conversation.created /
    # status_changed / updated), so this array has to stay free of activity
    # messages and private notes. It is NOT the dashboard seed — that one lives
    # in the conversation jbuilder and is deliberately wider. If this spec
    # breaks because someone mirrored the jbuilder here, the fix is to split
    # the broadcast audience, not to widen the query.
    it 'excludes activity messages and private notes' do
      chat_message = create(:message, conversation: conversation, account: conversation.account, message_type: :outgoing)
      create(:message, conversation: conversation, account: conversation.account, private: true)
      create(:message, conversation: conversation, account: conversation.account,
                       message_type: :activity, content: 'Conversation was marked resolved by John')

      expect(presenter.push_data[:messages].pluck(:id)).to eq([chat_message.id])
    end
  end

  describe '#push_data last_non_activity_message' do
    it 'is nil when the conversation has no non-activity messages' do
      expect(presenter.push_data[:last_non_activity_message]).to be_nil
    end

    it 'returns the last regular non-activity message' do
      message = create(:message, conversation: conversation, account: conversation.account,
                                 message_type: :outgoing, content: 'Hello there')

      data = presenter.push_data[:last_non_activity_message]

      expect(data[:id]).to eq(message.id)
      expect(data[:content]).to eq('Hello there')
    end

    # Deliberate, and the reason the contact allowlist exists: `non_activity_messages`
    # filters `message_type`, not `private`, so the agent-facing chat list preview
    # reads the private note when that is the newest thing that happened. Keeping
    # it out of the contact's browser is the broadcast layer's job (see
    # spec/listeners/action_cable_listener_spec.rb) — do NOT "fix" a leak by
    # narrowing this query, that would blank the preview for agents on the REST
    # path too, where no contact is listening.
    it 'includes private notes' do
      note = create(:message, conversation: conversation, account: conversation.account,
                              message_type: :outgoing, private: true, content: 'Internal only')

      expect(presenter.push_data[:last_non_activity_message][:id]).to eq(note.id)
      expect(described_class::CONTACT_PUSH_KEYS).not_to include(:last_non_activity_message)
    end

    # Counterpart of the seed: the chat list preview must never read
    # "Conversation was marked resolved by ...". If this and #push_data messages
    # ever agree on the same row for this scenario, the queries got merged.
    it 'skips activity messages' do
      message = create(:message, conversation: conversation, account: conversation.account,
                                 message_type: :outgoing, content: 'Hello there')
      create(:message, conversation: conversation, account: conversation.account,
                       message_type: :activity, content: 'Conversation was marked resolved by John')

      expect(presenter.push_data[:last_non_activity_message][:id]).to eq(message.id)
    end

    it 'skips reactions whose user-facing state is removed' do
      regular = create(:message, conversation: conversation, account: conversation.account,
                                 message_type: :outgoing, content: 'A real message')
      # A more recent reaction that has been toggled off should not become the
      # snapshot — otherwise the chat list preview shows a "ghost" reaction.
      create(:message, conversation: conversation, account: conversation.account,
                       message_type: :incoming, content: '',
                       content_attributes: { is_reaction: true, deleted: true,
                                             in_reply_to_external_id: 'ext_999' })

      data = presenter.push_data[:last_non_activity_message]

      expect(data[:id]).to eq(regular.id)
    end

    it 'enriches reactions with in_reply_to_snippet from the targeted message' do
      target = create(:message, conversation: conversation, account: conversation.account,
                                message_type: :incoming, content: 'Original message body that we expect to see in the snippet')
      reaction = create(:message, conversation: conversation, account: conversation.account,
                                  message_type: :incoming, content: '👍',
                                  content_attributes: { is_reaction: true, in_reply_to: target.id })

      data = presenter.push_data[:last_non_activity_message]

      expect(data[:id]).to eq(reaction.id)
      expect(data[:in_reply_to_snippet]).to start_with('Original message body')
    end

    it 'returns in_reply_to_snippet as a plain String, not SafeBuffer (regression)' do
      # `strip_tags` returns ActiveSupport::SafeBuffer, which Sidekiq's
      # strict-args check rejects when this hash flows into
      # ActionCableBroadcastJob.perform_later. The whole reactions controller
      # request 500s (and the UI shows a misleading toast) if this regresses.
      target = create(:message, conversation: conversation, account: conversation.account,
                                message_type: :incoming, content: '<p>HTML <strong>body</strong></p>')
      create(:message, conversation: conversation, account: conversation.account,
                       message_type: :incoming, content: '👍',
                       content_attributes: { is_reaction: true, in_reply_to: target.id })

      snippet = presenter.push_data[:last_non_activity_message][:in_reply_to_snippet]

      expect(snippet.class).to eq(String)
      expect(snippet).not_to include('<')
    end
  end

  # The cable copy is what moves the banner after a recheck, so it has to carry the field the
  # REST partial carries, on the same terms.
  describe '#push_data whatsapp_missing_checked_at' do
    it 'carries the date a WhatsApp number was found to have no account' do
      channel = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false)
      checked_at = 2.days.ago.change(usec: 0)
      contact_inbox = create(:contact_inbox, inbox: channel.inbox, whatsapp_missing_checked_at: checked_at)
      whatsapp_conversation = create(:conversation, account: channel.account, inbox: channel.inbox,
                                                    contact: contact_inbox.contact, contact_inbox: contact_inbox)

      expect(described_class.new(whatsapp_conversation).push_data[:whatsapp_missing_checked_at]).to eq(checked_at.to_i)
    end

    it 'leaves it out of conversations that are not on WhatsApp' do
      expect(presenter.push_data).not_to have_key(:whatsapp_missing_checked_at)
    end
  end
end
