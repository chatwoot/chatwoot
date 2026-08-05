class Captain::Conversation::InactivityFollowUpService
  MESSAGE_ATTRIBUTE = 'captain_inactivity_follow_up'.freeze

  pattr_initialize [:conversation!, :assistant!, :inactivity_cutoff_time!]

  def self.expired_conversation_ids(inbox:, cutoff_time:)
    Message.outgoing
           .where(inbox_id: inbox.id)
           .where('messages.additional_attributes @> ?', { MESSAGE_ATTRIBUTE => true }.to_json)
           .where('messages.created_at < ?', cutoff_time)
           .where(<<~SQL.squish, Message.message_types[:incoming])
             NOT EXISTS (
               SELECT 1
               FROM messages AS newer_incoming_messages
               WHERE newer_incoming_messages.conversation_id = messages.conversation_id
                 AND newer_incoming_messages.message_type = ?
                 AND newer_incoming_messages.id > messages.id
             )
           SQL
           .reorder(nil)
           .select(:conversation_id)
  end

  def active_message
    follow_up_message = conversation.messages.outgoing
                                    .where('additional_attributes @> ?', { MESSAGE_ATTRIBUTE => true }.to_json)
                                    .last
    return unless follow_up_message
    return if conversation.messages.incoming.exists?(['id > ?', follow_up_message.id])

    follow_up_message
  end

  def send!(reason:, content:)
    conversation.with_lock do
      conversation.reload
      next unless conversation.pending? && conversation.last_activity_at < inactivity_cutoff_time
      next if active_message

      create_private_note("Auto-followed up: #{reason}")
      conversation.messages.create!(
        message_type: :outgoing,
        sender: assistant,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: content,
        additional_attributes: { MESSAGE_ATTRIBUTE => true }
      )
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  def create_private_note(content)
    conversation.messages.create!(
      message_type: :outgoing,
      private: true,
      sender: assistant,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: content
    )
  end
end
