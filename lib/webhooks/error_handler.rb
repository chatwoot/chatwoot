class Webhooks::ErrorHandler
  SUPPORTED_EVENTS = %w[message_created message_incoming message_outgoing message_updated].freeze

  def initialize(payload, webhook_type, error)
    @payload = payload
    @webhook_type = webhook_type
    @error = error
  end

  def self.perform(payload, webhook_type, error)
    new(payload, webhook_type, error).perform
  end

  def perform
    return unless SUPPORTED_EVENTS.include?(@payload[:event])
    return unless message

    case @webhook_type
    when :agent_bot_webhook
      handle_agent_bot_error
    when :api_inbox_webhook
      handle_api_inbox_error
    end
  end

  private

  def handle_agent_bot_error
    conversation = message.conversation
    return unless conversation&.pending?
    return if conversation&.account&.keep_pending_on_bot_failure

    conversation.open!
    Conversations::ActivityMessageJob.perform_later(conversation, activity_message_params(conversation))
  end

  def handle_api_inbox_error
    Messages::StatusUpdateService.new(message, 'failed', @error.message).perform
  end

  def activity_message_params(conversation)
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: I18n.t('conversations.activity.agent_bot.error_moved_to_open')
    }
  end

  def message
    return if message_id.blank?

    @message ||= Message.find_by(id: message_id)
  end

  def message_id
    @payload[:id]
  end
end
