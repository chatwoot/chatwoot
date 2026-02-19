# frozen_string_literal: true

class Conversations::AutoLabelPendingConversationsJob < ApplicationJob
  queue_as :scheduled_jobs

  BATCH_LIMIT = 50

  def perform
    # Find accounts that have auto-assign enabled labels
    account_ids_with_auto_labels = Label.unscoped.where(allow_auto_assign: true).select(:account_id).distinct.pluck(:account_id)
    return if account_ids_with_auto_labels.empty?

    conversations_to_process.where(account_id: account_ids_with_auto_labels).limit(BATCH_LIMIT).each do |conversation|
      AutoAssignConversationJob.perform_later(conversation.id)
    end
  end

  private

  def conversations_to_process
    base = Conversation
           .where(status: Conversation.statuses[:open])
           .where(cached_label_list: [nil, ''])
           .where(created_at: 24.hours.ago..)
           .joins(:messages)
           .where(messages: { message_type: Message.message_types[:incoming] })
           .distinct

    never_triaged = base.where(last_triaged_at: nil)
    new_messages_since_triage = base.where.not(last_triaged_at: nil)
                                    .where('last_triaged_at < (SELECT MAX(m.created_at) FROM messages m ' \
                                           'WHERE m.conversation_id = conversations.id AND m.message_type = ?)',
                                           Message.message_types[:incoming])

    never_triaged.or(new_messages_since_triage)
  end
end
