# frozen_string_literal: true

class Conversations::AutoLabelPendingConversationsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # Find accounts that have auto-assign enabled labels
    account_ids_with_auto_labels = Label.unscoped.where(allow_auto_assign: true).select(:account_id).distinct.pluck(:account_id)
    return if account_ids_with_auto_labels.empty?

    # Find conversations that:
    # - Are open
    # - Have no labels
    # - Are older than 5 minutes
    # - Have at least 1 incoming message
    # - Belong to accounts with auto-assign labels
    conversations_to_process.where(account_id: account_ids_with_auto_labels).find_each do |conversation|
      AutoAssignConversationJob.perform_later(conversation.id)
    end
  end

  private

  def conversations_to_process
    Conversation
      .where(status: Conversation.statuses[:open])
      .where(cached_label_list: [nil, ''])
      .where(created_at: ...5.minutes.ago)
      .joins(:messages)
      .where(messages: { message_type: Message.message_types[:incoming] })
      .distinct
  end
end
