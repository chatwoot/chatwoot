class Captain::InboxPendingConversationsResolutionJob < ApplicationJob
  CAPTAIN_INFERENCE_RESOLVE_ACTIVITY_REASON = 'no outstanding questions'.freeze
  CAPTAIN_INFERENCE_WAITING_ACTIVITY_REASON = 'no reply from customer'.freeze
  CAPTAIN_INFERENCE_HANDOFF_ACTIVITY_REASON = 'needs a human agent'.freeze
  queue_as :low

  def perform(inbox)
    @captain_assistant = inbox.captain_assistant
    return if captain_assistant.blank? || captain_assistant.inactive_conversation_resolution_disabled?

    @inactivity_cutoff_time = Time.current - captain_assistant.inactivity_threshold_minutes.minutes

    if evaluate_conversation_completion?(inbox.account)
      perform_with_evaluation(inbox)
    else
      perform_time_based(inbox)
    end
  ensure
    Current.reset
  end

  private

  attr_reader :captain_assistant, :inactivity_cutoff_time

  def evaluate_conversation_completion?(account)
    account.feature_enabled?('captain_tasks') && captain_assistant.evaluate_inactive_conversations_before_resolving?
  end

  def perform_time_based(inbox)
    Current.executed_by = captain_assistant

    resolvable_pending_conversations(inbox).each do |conversation|
      resolve_time_based_conversation(conversation, inbox)
    end
  end

  def perform_with_evaluation(inbox)
    Current.executed_by = captain_assistant

    resolvable_pending_conversations(inbox).each do |conversation|
      if inactivity_messages(conversation).follow_up_unanswered?
        resolve_conversation(conversation, CAPTAIN_INFERENCE_WAITING_ACTIVITY_REASON, 'Auto-resolved: no reply to the follow-up')
        next
      end

      evaluation = evaluate_conversation(conversation, inbox)
      next unless still_resolvable_after_evaluation?(conversation)

      apply_evaluation(conversation, evaluation)
    end
  end

  def apply_evaluation(conversation, evaluation)
    case evaluation[:outcome]
    when 'complete'
      resolve_conversation(conversation, CAPTAIN_INFERENCE_RESOLVE_ACTIVITY_REASON, "Auto-resolved: #{evaluation[:reason]}")
    when 'waiting_on_customer'
      follow_up_or_resolve(conversation, evaluation[:reason])
    else
      handoff_conversation(conversation, evaluation[:reason])
    end
  end

  # The customer owes the next step, so Captain asks once instead of handing off. If the follow-up stays
  # unanswered for another inactivity window, the next run resolves the conversation without a new evaluation.
  def follow_up_or_resolve(conversation, reason)
    unless follow_up_allowed?(conversation)
      return resolve_conversation(conversation, CAPTAIN_INFERENCE_WAITING_ACTIVITY_REASON, "Auto-resolved, waiting on customer: #{reason}")
    end

    perform_locked_transition(conversation) do
      inactivity_messages(conversation).private_note("Follow-up sent, waiting on customer: #{reason}")
      inactivity_messages(conversation).follow_up
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Respect an assistant that sends no inactivity messages, and skip channels whose reply window has closed.
  def follow_up_allowed?(conversation)
    captain_assistant.send_inactivity_resolution_message? && conversation.can_reply?
  end

  def evaluate_conversation(conversation, inbox)
    Captain::ConversationCompletionService.new(
      account: inbox.account,
      conversation_display_id: conversation.display_id
    ).perform
  end

  def resolvable_pending_conversations(inbox)
    inbox.conversations.pending
         .where('last_activity_at < ?', inactivity_cutoff_time)
         .limit(Limits::BULK_ACTIONS_LIMIT)
  end

  def inactive_for_initial_action?(conversation) = conversation.last_activity_at < inactivity_cutoff_time

  def still_resolvable_after_evaluation?(conversation)
    conversation.reload
    conversation.pending? && inactive_for_initial_action?(conversation)
  rescue ActiveRecord::RecordNotFound
    false
  end

  def resolve_time_based_conversation(conversation, _inbox)
    resolved = false
    conversation.with_lock do
      conversation.reload
      next unless conversation.pending? && inactive_for_initial_action?(conversation)

      inactivity_messages(conversation).resolution
      conversation.resolved!
      resolved = true
    end
    return unless resolved

    Captain::ConversationEvents.resolved(
      conversation: conversation,
      assistant: captain_assistant,
      source: Captain::ConversationEvents::Sources::TIME_BASED,
      at: Time.current
    )
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def resolve_conversation(conversation, activity_reason, note)
    resolved = with_inference_activity_context(conversation, activity_reason) do
      perform_locked_transition(conversation) do
        conversation.resolved!
        inactivity_messages(conversation).private_note(note)
        inactivity_messages(conversation).resolution
      end
    end
    record_inference_resolution(conversation) if resolved
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def record_inference_resolution(conversation)
    Captain::ConversationEvents.resolved(
      conversation: conversation,
      assistant: captain_assistant,
      source: Captain::ConversationEvents::Sources::INFERENCE,
      at: Time.current
    )
  end

  def handoff_conversation(conversation, reason)
    handed_off = with_inference_activity_context(conversation, CAPTAIN_INFERENCE_HANDOFF_ACTIVITY_REASON) do
      perform_locked_transition(conversation) do
        conversation.bot_handoff!(dispatch_event: false)
        inactivity_messages(conversation).private_note("Auto-handoff: #{reason}")
        inactivity_messages(conversation).handoff
      end
    end
    return unless handed_off

    conversation.dispatch_bot_handoff_event
    Captain::ConversationEvents.handed_off(
      conversation: conversation,
      assistant: captain_assistant,
      source: Captain::ConversationEvents::Sources::INFERENCE,
      reason_category: :pending_clarification,
      at: Time.current
    )
    send_out_of_office_message_if_applicable(conversation.reload)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def perform_locked_transition(conversation)
    conversation.with_lock do
      conversation.reload
      next false unless conversation.pending? && inactive_for_initial_action?(conversation)

      yield
      true
    end
  end

  def with_inference_activity_context(conversation, reason, &)
    conversation.with_captain_activity_context(reason: reason, reason_type: :inference, &)
  end

  def send_out_of_office_message_if_applicable(conversation)
    ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(conversation) if conversation.campaign.blank?
  end

  def inactivity_messages(conversation)
    Captain::Conversation::InactivityMessageService.new(conversation: conversation, assistant: captain_assistant)
  end
end
