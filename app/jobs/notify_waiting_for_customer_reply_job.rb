class NotifyWaitingForCustomerReplyJob < ApplicationJob
  queue_as :high

  REMINDER_MESSAGE = 'Apakah Anda masih bersama kami? Jika masih memerlukan bantuan, silakan balas pesan ini. Kami siap membantu Anda.'

  STATUS_OPEN = 1
  MESSAGE_TYPE_TEMPLATE = 3
  CONTENT_TYPE_TEXT = 0
  SENDER_TYPE_USER = 'User'.freeze
  SENDER_TYPE_SYSTEM = 'System'.freeze
  SENDER_TYPE_AI_AGENT = 'AiAgent'.freeze
  MESSAGE_STATUS_SENT = 0

  def perform
    Rails.logger.info('[NotifyWaitingForCustomerReplyJob] Starting job to process waiting customers')
    process_all_conversations
    Rails.logger.info('[NotifyWaitingForCustomerReplyJob] Finished processing waiting customers')
  end

  private

  def process_all_conversations
    process_conversations(
      scope: conversations_to_remind,
      action: :remind,
      message: REMINDER_MESSAGE,
      update_attrs: { is_reminded: true }
    )
    process_conversations(
      scope: conversations_to_remind_after_assignee,
      action: :remind_after_assignee,
      message: REMINDER_MESSAGE,
      update_attrs: { is_reminded: true }
    )
  end

  def process_conversations(scope:, action:, message:, update_attrs:)
    scope.find_each do |conversation|
      Rails.logger.info("[NotifyWaitingForCustomerReplyJob] Processing conversation ##{conversation.id} for #{action}")
      create_message(conversation, message)
      conversation.update!(update_attrs)
      Rails.logger.info("[NotifyWaitingForCustomerReplyJob] Successfully processed conversation ##{conversation.id} for #{action}")
    rescue StandardError => e
      log_error(action.to_s.capitalize, conversation, e)
    end
  end

  def latest_messages_sql
    <<-SQL.squish
      SELECT DISTINCT ON (conversation_id) *
      FROM messages
      ORDER BY conversation_id, created_at DESC
    SQL
  end

  def conversations_to_remind
    Conversation
      .unscope(:order)
      .joins("INNER JOIN (#{latest_messages_sql}) AS latest_messages ON conversations.id = latest_messages.conversation_id")
      .open
      .where(assignee_id: nil)
      .where(is_reminded: false)
      .where('conversations.updated_at < ?', threshold_time)
      .where(latest_messages: { message_type: Message.message_types[:outgoing] })
      .where(latest_messages: { sender_type: SENDER_TYPE_AI_AGENT })
  end

  def conversations_to_remind_after_assignee
    Conversation
      .unscope(:order)
      .joins("INNER JOIN (#{latest_messages_sql}) AS latest_messages ON conversations.id = latest_messages.conversation_id")
      .open
      .where.not(assignee_id: nil)
      .where(is_reminded: false)
      .where('conversations.updated_at < ?', threshold_time)
      .where(latest_messages: { message_type: Message.message_types[:outgoing] })
      .where(latest_messages: { sender_type: SENDER_TYPE_USER })
  end

  def create_message(conversation, content)
    Message.create!(
      content: content,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      message_type: MESSAGE_TYPE_TEMPLATE,
      content_type: CONTENT_TYPE_TEXT,
      # sender_type: SENDER_TYPE_SYSTEM,
      sender_id: conversation.assignee_id,
      status: MESSAGE_STATUS_SENT
    )
  end

  def threshold_time
    5.minutes.ago
  end

  def log_error(action, conversation, exception)
    Rails.logger.error("[NotifyWaitingForCustomerReplyJob] #{action} failed for ##{conversation.id}: #{exception.message}")
  end
end
