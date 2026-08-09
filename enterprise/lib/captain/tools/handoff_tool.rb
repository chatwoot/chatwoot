class Captain::Tools::HandoffTool < Captain::Tools::BasePublicTool
  description 'Hand off the conversation to a human agent when unable to assist further'
  param :reason, type: 'string', desc: 'The reason why handoff is needed (optional)', required: false

  def perform(tool_context, reason: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    # Log the handoff with reason
    log_tool_usage('tool_handoff', {
                     conversation_id: conversation.id,
                     reason: reason || 'Agent requested handoff'
                   })

    # Use existing handoff mechanism from ResponseBuilderJob
    handoff_result = trigger_handoff(tool_context, conversation, reason)
    return 'Handoff skipped because a newer customer message arrived' if handoff_result == :stale
    return 'Handoff skipped because the conversation changed' unless handoff_result == :completed

    "Conversation handed off to human support team#{" (Reason: #{reason})" if reason}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to handoff conversation'
  end

  private

  def trigger_handoff(tool_context, conversation, reason)
    return trigger_legacy_handoff(tool_context, conversation, reason) unless captain_v2_enabled?

    note = nil
    handoff_result = conversation.with_lock do
      next :changed unless conversation.pending?
      next :stale if newer_customer_message_arrived?(tool_context.state)

      # post the reason as a private note
      note = conversation.messages.create!(
        message_type: :outgoing, private: true, sender: @assistant,
        account: conversation.account, inbox: conversation.inbox, content: reason
      )

      conversation.bot_handoff!(dispatch_event: false)
      :completed
    end

    return handoff_result unless handoff_result == :completed

    # Session capture attributes the run to this note so agents can inspect the
    # generation path on the handoff reason instead of the canned follow-up message.
    # A reason-less note has no content and never renders in the dashboard, so
    # leave it unrecorded and let capture fall back to the follow-up message.
    record_handoff_note(tool_context, note) if reason.present?

    tool_context.state[:captain_v2_handoff_tool_completed] = true
    # Queue the event after the state change commits so notification jobs always see the open conversation.
    conversation.dispatch_bot_handoff_event
    emit_tool_handoff_event(conversation)

    # Send out of office message if applicable (since template messages were suppressed while Captain was handling)
    send_out_of_office_message_if_applicable(conversation)
    :completed
  end

  def trigger_legacy_handoff(tool_context, conversation, reason)
    note = conversation.messages.create!(
      message_type: :outgoing, private: true, sender: @assistant,
      account: conversation.account, inbox: conversation.inbox, content: reason
    )
    record_handoff_note(tool_context, note) if reason.present?
    conversation.bot_handoff!
    emit_tool_handoff_event(conversation)
    send_out_of_office_message_if_applicable(conversation)
    :completed
  end

  def emit_tool_handoff_event(conversation)
    Captain::ConversationEvents.handed_off(conversation: conversation, assistant: @assistant,
                                           source: Captain::ConversationEvents::Sources::TOOL, at: Time.current)
  end

  def record_handoff_note(tool_context, note)
    metadata = tool_context.state[:cw_metadata] ||= {}
    metadata[:handoff_note_id] = note.id
  end

  def send_out_of_office_message_if_applicable(conversation)
    # Campaign conversations should never receive OOO templates — the campaign itself
    # serves as the initial outreach, and OOO would be confusing in that context.
    return if conversation.campaign.present?

    ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(conversation)
  end

  # TODO: Future enhancement - Add team assignment capability
  # This tool could be enhanced to:
  # 1. Accept team_id parameter for routing to specific teams
  # 2. Set conversation priority based on handoff reason
  # 3. Add metadata for intelligent agent assignment
  # 4. Support escalation levels (L1 -> L2 -> L3)
  #
  # Example future signature:
  # param :team_id, type: 'string', desc: 'ID of team to assign conversation to', required: false
  # param :priority, type: 'string', desc: 'Priority level (low/medium/high/urgent)', required: false
  # param :escalation_level, type: 'string', desc: 'Support level (L1/L2/L3)', required: false
end
