class NotifyWaitingForAgentReplyJob < ApplicationJob
  queue_as :default

  WAITING_MESSAGE = 'Maaf kamu belum dapat balasan ya. Saya akan segera menghubungkan kamu dengan agen manusia untuk membantu proses pengecekannya. Terima kasih sudah bersabar! 🙏'
  WAITING_MESSAGE_FOR_AGENT_OFFLINE = 'Saat init tim kami sedang offline. Tapi tenang, pesan kamu sudah kami terima dan akan kami balas saat jam operasional atau saat tim kami online kembali 🙏'

  STATUS_OPEN = 1
  MESSAGE_TYPE_TEMPLATE = 3
  CONTENT_TYPE_TEXT = 0
  SENDER_TYPE_USER = 'User'.freeze
  SENDER_TYPE_SYSTEM = 'System'.freeze
  SENDER_TYPE_AI_AGENT = 'AiAgent'.freeze
  MESSAGE_STATUS_SENT = 0

  def perform
    process_conversations(
      scope: conversations_to_remind,
      action: :remind,
      update_attrs: { is_handover_reminded: false }
    )
  end

  private

  def process_conversations(scope:, action:, update_attrs:)
    scope.find_each do |conversation|
      Rails.logger.info("[NotifyWaitingForAgentReplyJob] Processing conversation ##{conversation.id} for #{action}")
      message_to_send = availability_agent?(conversation.inbox_id) ? WAITING_MESSAGE : WAITING_MESSAGE_FOR_AGENT_OFFLINE
      create_message(conversation, message_to_send)
      conversation.update!(update_attrs)
      Rails.logger.info("[NotifyWaitingForAgentReplyJob] Successfully processed conversation ##{conversation.id} for #{action}")
    rescue StandardError => e
      log_error(action.to_s.capitalize, conversation, e)
    end
  end

  def availability_agent?(inbox_id)
    agent_ids = InboxMember.where(inbox_id: inbox_id).pluck(:user_id)
    User.exists?(id: agent_ids, availability: User.availabilities[:online])
  end

  def conversations_to_remind
    Conversation
      .open
      .where(is_handover_reminded: true)
      .where.not(assignee_id: nil)
      .where('conversations.updated_at < ?', threshold_time)
      .group('conversations.id')
  end

  def create_message(conversation, content)
    Message.create!(
      content: content,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      message_type: MESSAGE_TYPE_TEMPLATE,
      content_type: CONTENT_TYPE_TEXT,
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
