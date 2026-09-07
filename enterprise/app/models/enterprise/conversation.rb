module Enterprise::Conversation
  attr_accessor :captain_activity_reason, :captain_activity_reason_type

  def list_of_keys
    super + %w[sla_policy_id]
  end

  # Surface call lifecycle changes to the FE: writes to additional_attributes
  # call_status/call_direction should rebroadcast conversation_updated.
  def allowed_keys?
    super || call_attributes_changed?
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

    # Keep Captain ownership writes off until typed-assignee readers are deployed to every web and worker process.
    # Remove this guard in the follow-up rollout after all legacy AgentBot readers have been drained.
    return unless GlobalConfigService.load('ENABLE_CAPTAIN_CONVERSATION_ASSIGNMENT', false)

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
