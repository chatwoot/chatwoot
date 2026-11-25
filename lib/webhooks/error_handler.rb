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

  # Shared with Webhooks::Trigger, whose 429/500 ladder ends in its own handler.
  # A handoff, not a bare `open!`: with the bot still the assignee the conversation stays out of
  # Unassigned and out of auto-assignment, open and owned by nobody who can answer it.
  # Locked because two messages in a row exhaust their ladders milliseconds apart, and both
  # handlers would read `pending` before either wrote, posting the note twice.
  def self.hand_off_after_bot_failure(conversation)
    return unless conversation&.pending?
    return if conversation.account&.keep_pending_on_bot_failure

    handed_off = conversation.with_lock do
      next false unless conversation.pending?

      conversation.bot_handoff!(dispatch_event: false)
      true
    end
    return unless handed_off

    conversation.dispatch_bot_handoff_event
    Conversations::ActivityMessageJob.perform_later(conversation, activity_message_params(conversation))
  end

  def self.activity_message_params(conversation)
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: I18n.t('conversations.activity.agent_bot.error_moved_to_open')
    }
  end
  private_class_method :activity_message_params

  def perform
    return unless SUPPORTED_EVENTS.include?(@payload[:event])
    return unless message

    # `:agent_bot_observer_webhook` deliberately matches nothing: an observer never owns the
    # conversation, so there is nothing to hand over when its deliveries are exhausted.
    case @webhook_type
    when :agent_bot_webhook
      handle_agent_bot_error
    when :api_inbox_webhook
      handle_api_inbox_error
    end
  end

  private

  def handle_agent_bot_error
    self.class.hand_off_after_bot_failure(message.conversation)
  end

  def handle_api_inbox_error
    # ONLY A MESSAGE STILL IN ITS INITIAL `sent` STATE IS ONE THIS DELIVERY CAN STILL SPEAK FOR.
    # The retries put minutes between the send and this handler, and the channel can report the
    # message delivered or read inside that window. `Messages::StatusUpdateService` refuses only
    # `read` -> `delivered`, so without this guard a failure decided minutes ago lands on top of a
    # message the customer already has, and the agent is shown a resend they must not make.
    # Locked because the channel's own update races this read, and the lock is what makes the
    # channel's write wait rather than interleave.
    message.with_lock do
      break unless message.sent?

      Messages::StatusUpdateService.new(message, 'failed', @error.message).perform
    end
  end

  def message
    return if message_id.blank?

    @message ||= Message.find_by(id: message_id)
  end

  def message_id
    @payload[:id]
  end
end
