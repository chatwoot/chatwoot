class AutoResolveIdleConversationsJob < ApplicationJob
  queue_as :default

  REMINDER_MESSAGE = 'Apakah Anda masih bersama kami? Jika masih memerlukan bantuan, silakan balas pesan ini. Kami siap membantu Anda.'
  RESOLUTION_MESSAGE = 'Karena belum ada respon, sesi chat ini akan kami akhiri. Jika Anda membutuhkan bantuan di lain waktu, jangan ragu untuk menghubungi kami kembali. Terima kasih.'

  STATUS_OPEN = 1
  MESSAGE_TYPE_OUTGOING = 1
  CONTENT_TYPE_TEXT = 0
  SENDER_TYPE_USER = 'User'.freeze
  MESSAGE_STATUS_SENT = 0

  def perform
    process_conversations(
      scope: conversations_to_remind,
      action: :remind,
      message: REMINDER_MESSAGE,
      update_attrs: { is_reminded: true }
    )
    process_conversations(
      scope: conversations_to_resolve,
      action: :resolve,
      message: RESOLUTION_MESSAGE,
      update_attrs: { status: STATUS_OPEN, assignee_id: nil, is_reminded: false }
    )
  end

  private

  def process_conversations(scope:, action:, message:, update_attrs:)
    scope.find_each do |conversation|
      create_message(conversation, message)
      conversation.update!(update_attrs)
    rescue StandardError => e
      log_error(action.to_s.capitalize, conversation, e)
    end
  end

  def conversations_to_remind
    Conversation
      .open
      .where(is_reminded: false)
      .where('updated_at < ?', threshold_time)
      .last_messaged_conversations
      .where(grouped_conversations: { status: STATUS_OPEN })
      .group('conversations.id')
  end

  def conversations_to_resolve
    Conversation
      .open
      .where(is_reminded: true)
      .where('updated_at < ?', threshold_time)
      .last_messaged_conversations
      .where(grouped_conversations: { status: STATUS_OPEN })
      .group('conversations.id')
  end

  def create_message(conversation, content)
    Message.create!(
      content: content,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      message_type: MESSAGE_TYPE_OUTGOING,
      content_type: CONTENT_TYPE_TEXT,
      sender_type: SENDER_TYPE_USER,
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
