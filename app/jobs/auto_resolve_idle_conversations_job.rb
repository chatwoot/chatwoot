class AutoResolveIdleConversationsJob < ApplicationJob
  queue_as :default

  RESOLUTION_MESSAGE = 'Karena belum ada respon, sesi chat ini akan kami akhiri. Jika Anda membutuhkan bantuan di lain waktu, jangan ragu untuk menghubungi kami kembali. Terima kasih.'

  STATUS_OPEN = 1
  MESSAGE_TYPE_TEMPLATE = 3
  CONTENT_TYPE_TEXT = 0
  SENDER_TYPE_USER = 'User'.freeze
  SENDER_TYPE_SYSTEM = 'System'.freeze
  SENDER_TYPE_AI_AGENT = 'AiAgent'.freeze
  MESSAGE_STATUS_SENT = 0

  def perform
    Rails.logger.info('[AutoResolveIdleConversationsJob] Starting job to process idle conversations')
    process_conversations(
      scope: conversations_to_resolve,
      action: :resolve,
      message: RESOLUTION_MESSAGE,
      update_attrs: { status: STATUS_OPEN, assignee_id: nil, is_reminded: false }
    )
    Rails.logger.info('[AutoResolveIdleConversationsJob] Finished processing idle conversations')
  end

  private

  def process_conversations(scope:, action:, message:, update_attrs:)
    scope.find_each do |conversation|
      Rails.logger.info("[AutoResolveIdleConversationsJob] Processing conversation ##{conversation.id} for #{action}")
      create_message(conversation, message)
      conversation.update!(update_attrs)
      Rails.logger.info("[AutoResolveIdleConversationsJob] Successfully processed conversation ##{conversation.id} for #{action}")
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

  def conversations_to_resolve
    Conversation
      .unscope(:order)
      .joins("INNER JOIN (#{latest_messages_sql}) AS latest_messages ON conversations.id = latest_messages.conversation_id")
      .open
      .where(is_reminded: true)
      .where('conversations.updated_at < ?', threshold_time)
    # .where(latest_messages: { message_type: Message.message_types[:outgoing] })
    # .where(latest_messages: { sender_type: SENDER_TYPE_SYSTEM })
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
    Rails.logger.error("[AutoResolveIdleConversationsJob] #{action} failed for ##{conversation.id}: #{exception.message}")
  end
end
