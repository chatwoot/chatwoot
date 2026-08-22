class MessageTemplates::HookExecutionService
  pattr_initialize [:message!]

  def perform
    return if conversation.last_incoming_message.blank?
    return if message.auto_reply_email?

    trigger_templates
  end

  private

  delegate :inbox, :conversation, to: :message
  delegate :contact, to: :conversation

  def trigger_templates
    ::MessageTemplates::Template::OutOfOffice.new(conversation: conversation).perform if should_send_out_of_office_message?
    ::MessageTemplates::Template::Greeting.new(conversation: conversation).perform if should_send_greeting?
    ::MessageTemplates::Template::EmailCollect.new(conversation: conversation).perform if inbox.enable_email_collect && should_send_email_collect?

    schedule_captain_response if captain_conversation_message?
  end

  # Restored open-source equivalent of the Captain trigger that used to live in
  # the enterprise hook mod: every inbound customer message in a
  # Captain-connected inbox is handed to the response scheduler, which runs the
  # simple-reply layer first and falls back to the LLM when nothing matches.
  def schedule_captain_response
    Captain::Conversation::ResponseSchedulerService.new(message: message).perform
  end

  def captain_conversation_message?
    return false unless message.captain_response_triggering?
    return false if inbox.captain_assistant.blank?
    return false if inbox.external_bot_active?

    engage_captain_for_conversation
    conversation.pending?
  end

  # Conversations only auto-start pending when the assistant is attached at
  # creation time; ones created before (or restored/reused) stay open and
  # never get scheduled. Pend those here so the first customer message hands
  # them to Captain, unless a human is already working the thread.
  def engage_captain_for_conversation
    return if conversation.pending?
    return unless conversation_available_for_captain?

    conversation.pending!
  end

  # Captain may take an open conversation when the humans it's assigned to are
  # offline, so a customer isn't left waiting on an agent who isn't responding.
  # Unassigned conversations are fair game; an assigned one is handed to Captain
  # only when none of its assignees (or the assigned team's members) is online.
  # A conversation with an existing human reply is NOT auto-taken; an agent can
  # still opt it in manually with the per-conversation bot-reply toggle.
  def conversation_available_for_captain?
    return false unless conversation.open?
    return true if captain_reply_manually_enabled?
    return false if conversation.first_reply_created_at.present?
    return false if assigned_agent_online?

    true
  end

  def captain_reply_manually_enabled?
    conversation.custom_attributes['ai_reply_enabled'].to_s == 'true'
  end

  def assigned_agent_online?
    (conversation_assignee_user_ids & online_user_ids).any?
  end

  def conversation_assignee_user_ids
    user_ids = [conversation.assignee_id]
    user_ids += conversation.team&.members&.pluck(:user_id) if conversation.team_id.present?
    user_ids.compact.uniq
  end

  def online_user_ids
    ::OnlineStatusTracker.get_available_users(conversation.account_id)
                         .select { |_user_id, status| status.eql?('online') }
                         .keys
                         .map(&:to_i)
  end

  def should_send_out_of_office_message?
    return false if out_of_office_suppressed?
    # should not send for outbound messages
    return false unless message.incoming?
    # prevents sending out-of-office message if an agent has sent a message in last 5 minutes
    # ensures better UX by not interrupting active conversations at the end of business hours
    return false if conversation.messages.outgoing.where(private: false).exists?(['created_at > ?', 5.minutes.ago])

    inbox.out_of_office? && conversation.messages.today.template.empty? && inbox.out_of_office_message.present?
  end

  def out_of_office_suppressed?
    captain_handling_conversation? || conversation.campaign.present? || conversation.tweet?
  end

  def first_message_from_contact?
    conversation.messages.outgoing.count.zero? && conversation.messages.template.count.zero?
  end

  def should_send_greeting?
    return false if captain_handling_conversation?
    return false if conversation.campaign.present?
    # should not send if its a tweet message
    return false if conversation.tweet?

    first_message_from_contact? && inbox.greeting_enabled? && inbox.greeting_message.present?
  end

  def email_collect_was_sent?
    conversation.messages.where(content_type: 'input_email').present?
  end

  # TODO: we should be able to reduce this logic once we have a toggle for email collect messages
  def should_send_email_collect?
    return false if captain_handling_conversation?
    return false if conversation.campaign.present?

    !contact_has_email? && inbox.web_widget? && !email_collect_was_sent?
  end

  def contact_has_email?
    contact.email
  end

  def captain_handling_conversation?
    conversation.pending? && inbox.captain_assistant.present?
  end
end
MessageTemplates::HookExecutionService.prepend_mod_with('MessageTemplates::HookExecutionService')
