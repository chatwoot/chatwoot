class Captain::Tools::HandoffTool < Captain::Tools::BasePublicTool
  # LLM-selectable reasons are a subset of the outcome enum. System lifecycle
  # paths emit the remaining categories, such as usage limits and pending clarification.
  REASON_CATEGORIES = %w[customer_request missing_knowledge unsupported_request policy_restriction tool_failure].freeze

  description 'Hand off the conversation to a human agent when unable to assist further'
  params do
    string :reason, description: 'The reason why handoff is needed (optional)', required: false
    string :reason_category, enum: REASON_CATEGORIES, description: 'Reporting category for why the handoff is needed'
  end

  # Agents::ToolWrapper reads `tool.class.params`, while ruby_llm treats a
  # no-argument call as a schema reset. Keep the compatibility fix local to the
  # only tool that uses ruby_llm's block schema DSL.
  def self.params(schema = nil, &)
    return params_schema_definition if schema.nil? && !block_given?

    super
  end

  def perform(tool_context, reason: nil, reason_category: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    # Log the handoff with reason
    log_tool_usage('tool_handoff', {
                     conversation_id: conversation.id,
                     reason: reason || 'Agent requested handoff'
                   })

    # Use existing handoff mechanism from ResponseBuilderJob
    handoff_result = trigger_handoff(tool_context, conversation, reason, reason_category)
    return 'Handoff skipped because a newer customer message arrived' if handoff_result == :stale
    return 'Handoff skipped because the conversation changed' unless handoff_result == :completed

    "Conversation handed off to human support team#{" (Reason: #{reason})" if reason}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to handoff conversation'
  end

  private

  def trigger_handoff(tool_context, conversation, reason, reason_category)
    return trigger_legacy_handoff(tool_context, conversation, reason, reason_category) unless captain_v2_enabled?

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
    emit_tool_handoff_event(conversation, reason_category)

    # Send out of office message if applicable (since template messages were suppressed while Captain was handling)
    send_out_of_office_message_if_applicable(conversation)
    :completed
  end

  def trigger_legacy_handoff(tool_context, conversation, reason, reason_category)
    note = conversation.messages.create!(
      message_type: :outgoing, private: true, sender: @assistant,
      account: conversation.account, inbox: conversation.inbox, content: reason
    )
    record_handoff_note(tool_context, note) if reason.present?
    conversation.bot_handoff!
    emit_tool_handoff_event(conversation, reason_category)
    send_out_of_office_message_if_applicable(conversation)
    :completed
  end

  def emit_tool_handoff_event(conversation, reason_category)
    Captain::ConversationEvents.handed_off(conversation: conversation, assistant: @assistant,
                                           source: Captain::ConversationEvents::Sources::TOOL,
                                           reason_category: normalize_reason_category(reason_category),
                                           at: Time.current)
  end

  # Tool execution does not enforce the schema enum, and an unknown category
  # would fail the outcome's validated enum after the handoff already happened.
  # Record those handoffs as unclassified instead.
  def normalize_reason_category(reason_category)
    category = reason_category.to_s
    category if REASON_CATEGORIES.include?(category)
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
