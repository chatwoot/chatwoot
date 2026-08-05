# rubocop:disable Metrics/ClassLength
class Captain::InboxPendingConversationsResolutionJob < ApplicationJob
  CAPTAIN_INFERENCE_RESOLVE_ACTIVITY_REASON = 'no outstanding questions'.freeze
  CAPTAIN_INFERENCE_HANDOFF_ACTIVITY_REASON = 'pending clarification from customer'.freeze
  queue_as :low

  def perform(inbox)
    @captain_assistant = inbox.captain_assistant
    return if captain_assistant.blank? || captain_assistant.inactive_conversation_resolution_disabled?

    now = Time.current
    @inactivity_cutoff_time = now - captain_assistant.inactivity_threshold_minutes.minutes
    @follow_up_resolution_cutoff_time = now - captain_assistant.follow_up_resolution_threshold_minutes.minutes

    if evaluate_conversation_completion?(inbox.account)
      perform_with_evaluation(inbox)
    else
      perform_time_based(inbox)
    end
  ensure
    Current.reset
  end

  private

  attr_reader :captain_assistant, :inactivity_cutoff_time, :follow_up_resolution_cutoff_time

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

    candidate_pending_conversations(inbox).each do |conversation|
      next if process_pending_follow_up(conversation, inbox)
      next unless inactive_for_initial_action?(conversation)

      evaluation = evaluate_conversation(conversation, inbox)
      next unless still_resolvable_after_evaluation?(conversation)

      perform_evaluated_action(conversation, inbox, evaluation)
    end
  end

  def perform_evaluated_action(conversation, inbox, evaluation)
    case evaluation_action(evaluation)
    when 'resolve'
      resolve_conversation(conversation, inbox, evaluation[:reason])
    when 'follow_up'
      if captain_assistant.follow_up_before_resolving? && evaluation[:follow_up_message].present?
        follow_up_conversation(conversation, evaluation[:reason], evaluation[:follow_up_message])
      else
        handoff_conversation(conversation, evaluation[:reason])
      end
    else
      handoff_conversation(conversation, evaluation[:reason])
    end
  end

  def evaluation_action(evaluation)
    evaluation[:action].presence_in(Captain::ConversationCompletionSchema::ACTIONS) || (evaluation[:complete] ? 'resolve' : 'handoff')
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

  def candidate_pending_conversations(inbox)
    cutoff_time = if captain_assistant.follow_up_before_resolving?
                    [inactivity_cutoff_time, follow_up_resolution_cutoff_time].max
                  else
                    inactivity_cutoff_time
                  end

    inbox.conversations.pending
         .where('last_activity_at < ?', cutoff_time)
         .limit(Limits::BULK_ACTIONS_LIMIT)
  end

  def inactive_for_initial_action?(conversation) = conversation.last_activity_at < inactivity_cutoff_time

  def still_resolvable_after_evaluation?(conversation)
    conversation.reload
    conversation.pending? && inactive_for_initial_action?(conversation)
  rescue ActiveRecord::RecordNotFound
    false
  end

  def process_pending_follow_up(conversation, inbox)
    follow_up_message = follow_up_service(conversation).active_message
    return false unless follow_up_message
    return true unless follow_up_message.created_at < follow_up_resolution_cutoff_time

    resolved = with_inference_activity_context(conversation, CAPTAIN_INFERENCE_RESOLVE_ACTIVITY_REASON) do
      resolve_pending_follow_up(conversation, inbox)
    end
    record_inference_resolution(conversation) if resolved
    true
  rescue ActiveRecord::RecordNotFound
    true
  end

  def resolve_time_based_conversation(conversation, inbox)
    resolved = false
    conversation.with_lock do
      conversation.reload
      next unless conversation.pending? && inactive_for_initial_action?(conversation)

      create_resolution_message(conversation, inbox)
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

  def resolve_conversation(conversation, inbox, reason)
    resolved = with_inference_activity_context(conversation, CAPTAIN_INFERENCE_RESOLVE_ACTIVITY_REASON) do
      perform_locked_transition(conversation) do
        conversation.resolved!
        create_private_note(conversation, "Auto-resolved: #{reason}")
        create_resolution_message(conversation, inbox)
      end
    end
    record_inference_resolution(conversation) if resolved
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def follow_up_conversation(conversation, reason, message)
    follow_up_service(conversation).send!(reason: reason, content: message)
  end

  def record_inference_resolution(conversation)
    Captain::ConversationEvents.resolved(
      conversation: conversation,
      assistant: captain_assistant,
      source: Captain::ConversationEvents::Sources::INFERENCE,
      at: Time.current
    )
  end

  def follow_up_service(conversation)
    Captain::Conversation::InactivityFollowUpService.new(
      conversation: conversation,
      assistant: captain_assistant,
      inactivity_cutoff_time: inactivity_cutoff_time
    )
  end

  def handoff_conversation(conversation, reason)
    handed_off = with_inference_activity_context(conversation, CAPTAIN_INFERENCE_HANDOFF_ACTIVITY_REASON) do
      perform_locked_transition(conversation) do
        conversation.bot_handoff!(dispatch_event: false)
        create_private_note(conversation, "Auto-handoff: #{reason}")
        create_handoff_message(conversation)
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

  def resolve_pending_follow_up(conversation, inbox)
    conversation.with_lock do
      conversation.reload
      follow_up_message = follow_up_service(conversation).active_message
      next false unless conversation.pending? && follow_up_message
      next false unless follow_up_message.created_at < follow_up_resolution_cutoff_time

      conversation.resolved!
      create_private_note(conversation, 'Auto-resolved after follow-up: Customer did not reply')
      create_resolution_message(conversation, inbox)
      true
    end
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

  def create_private_note(conversation, content)
    conversation.messages.create!(
      message_type: :outgoing,
      private: true,
      sender: captain_assistant,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: content
    )
  end

  def create_resolution_message(conversation, inbox)
    return unless captain_assistant.send_inactivity_resolution_message?

    I18n.with_locale(inbox.account.locale) do
      resolution_message = captain_assistant.config['resolution_message']
      conversation.messages.create!(
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: resolution_message.presence || I18n.t('conversations.activity.auto_resolution_message'),
        sender: captain_assistant
      )
    end
  end

  def create_handoff_message(conversation)
    handoff_message = captain_assistant.config['handoff_message']
    return if handoff_message.blank?

    conversation.messages.create!(
      message_type: :outgoing,
      sender: captain_assistant,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: handoff_message,
      preserve_waiting_since: true
    )
  end
end
# rubocop:enable Metrics/ClassLength
