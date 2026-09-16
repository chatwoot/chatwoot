module Enterprise::Message
  def self.prepended(base)
    base.class_eval do
      has_one :call, class_name: 'Call', foreign_key: :message_id, dependent: :nullify, inverse_of: :message

      scope :with_call, -> { includes(call: [:contact, { inbox: :channel }]) }
      # Scheduling and freshness checks must share this scope so an email auto reply cannot cancel a pending response.
      scope :captain_response_triggering, lambda {
        incoming.joins(:inbox).where(
          "((messages.content_attributes #>> '{}')::jsonb -> 'email' ->> 'auto_reply') IS DISTINCT FROM 'true' OR " \
          "(messages.content_type != :incoming_email AND inboxes.channel_type != 'Channel::Email')",
          incoming_email: content_types[:incoming_email]
        )
      }
    end
  end

  def push_event_data
    data = super
    data[:call] = call.push_event_data if content_type == 'voice_call' && call.present?
    data
  end

  def captain_response_triggering?
    return incoming? && !auto_reply_email? unless persisted?

    self.class.captain_response_triggering.exists?(id: id)
  end

  private

  def reopen_resolved_conversation
    assistant = conversation.inbox.captain_assistant

    return super if assistant.blank? || conversation.inbox.external_bot_active?
    return conversation.open! unless assistant.engages?(conversation.contact, conversation)

    super
  end

  def mark_pending_conversation_as_open_for_human_response
    return unless captain_pending_conversation?
    return unless human_response?
    return if private?
    return if template_bootstrap_message?

    previous_user = Current.user
    previous_executed_by = Current.executed_by
    Current.user = nil
    Current.executed_by = nil

    begin
      conversation.ai_assignee = nil if conversation.ai_assignee_type == 'Captain::Assistant'
      conversation.open!
      return unless conversation.saved_change_to_status?

      create_captain_auto_open_activity_message
    ensure
      Current.user = previous_user
      Current.executed_by = previous_executed_by
    end
  end

  def captain_pending_conversation?
    return false unless conversation.pending?

    ::CaptainInbox.exists?(inbox_id: conversation.inbox_id)
  end

  def template_bootstrap_message?
    additional_attributes['template_params'].present? &&
      !conversation.messages.incoming.exists?
  end

  def create_captain_auto_open_activity_message
    ::Conversations::ActivityMessageJob.perform_later(
      conversation,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: I18n.t('conversations.activity.captain.auto_opened_after_agent_reply', locale: conversation.account.locale)
    )
  end
end
