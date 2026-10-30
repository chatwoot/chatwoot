module Enterprise::Conversation
  attr_accessor :captain_activity_reason, :captain_activity_reason_type
  # Set on the conversation an inbound Twilio call opens, before the call that rings exists
  attr_writer :call_ringing

  def can_reply?
    return false if contact_inbox.anonymous_caller?

    super
  end

  def list_of_keys
    super + %w[sla_policy_id]
  end

  # Surface call lifecycle changes to the FE: writes to additional_attributes
  # call_status/call_direction should rebroadcast conversation_updated.
  def allowed_keys?
    super || call_attributes_changed?
  end

  # Auto-assignment holds off while an inbound Twilio call rings, so the agent who answers gets
  # the conversation
  def call_ringing?
    return false unless inbox.twilio?

    @call_ringing || Call.exists?(conversation_id: id, provider: :twilio, direction: :incoming, status: 'ringing')
  end

  # Once its call stops ringing unanswered, the conversation gets the assignment it held off
  def auto_assign_after_call
    return unless open? && should_run_auto_assignment?

    if inbox.auto_assignment_v2_enabled?
      AutoAssignment::AssignmentJob.enqueue_for_inbox(inbox_id)
    else
      AutoAssignment::AgentAssignmentService.new(conversation: self, allowed_agent_ids: legacy_allowed_agent_ids).perform
    end
  end

  def with_captain_activity_context(reason:, reason_type:)
    previous_reason = captain_activity_reason
    previous_reason_type = captain_activity_reason_type

    self.captain_activity_reason = reason
    self.captain_activity_reason_type = reason_type
    yield
  ensure
    self.captain_activity_reason = previous_reason
    self.captain_activity_reason_type = previous_reason_type
  end

  private

  def should_run_auto_assignment?
    super && !call_ringing?
  end

  def clear_invalid_ai_assignee
    super
    self.ai_assignee = nil if status_changed? && open? && ai_assignee_type == 'Captain::Assistant'
  end

  def determine_conversation_status
    super
    return unless pending?
    return if inbox.external_bot_active?

    assistant = inbox.captain_assistant
    return if assistant.blank?

    unless assistant.engages?(contact, self)
      self.status = :open
      return
    end

    self.ai_assignee = assistant if assignee_id.blank?
  end

  def handle_resolved_status_change
    super
    update_applied_sla_completion
  end

  def update_applied_sla_completion
    return unless saved_change_to_status?

    current_applied_sla = applied_sla
    return if current_applied_sla.blank?

    terminal_sla = current_applied_sla.sla_status.in?(%w[hit missed])
    return if terminal_sla && (!resolved? || current_applied_sla.completed_at.present?)

    current_applied_sla.update!(completed_at: resolved? ? Time.current : nil)
  end

  def call_attributes_changed?
    return false if previous_changes['additional_attributes'].blank?

    # Compare before/after values for call keys — checking key presence alone
    # rebroadcasts on any unrelated additional_attributes write once the keys exist.
    before, after = previous_changes['additional_attributes']
    %w[call_status call_direction].any? { |key| (before || {})[key] != (after || {})[key] }
  end
end
