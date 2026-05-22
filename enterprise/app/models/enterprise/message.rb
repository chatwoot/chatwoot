module Enterprise::Message
  def self.prepended(base)
    base.class_eval do
      has_one :call, class_name: 'Call', foreign_key: :message_id, dependent: :nullify, inverse_of: :message

      scope :with_call, -> { includes(call: [:contact, { inbox: :channel }]) }
    end
  end

  def push_event_data
    data = super
    data[:call] = call.push_event_data if content_type == 'voice_call' && call.present?
    data
  end

  def captain_run_context
    captain = additional_attributes&.dig('captain')
    return unless captain&.dig('version') == 'v2'

    run_context = (captain['run'] || {}).deep_dup
    messages = Array(run_context['messages']).map(&:deep_dup)
    restore_captain_final_response(messages)

    run_context.merge('messages' => messages)
  end

  private

  def restore_captain_final_response(messages)
    final_assistant_message = messages.reverse.find { |message| message['role'] == 'assistant' }
    return unless final_assistant_message

    content_hash = final_assistant_message['content'].is_a?(Hash) ? final_assistant_message['content'] : {}
    final_assistant_message['content'] = content_hash.merge('response' => content)
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
