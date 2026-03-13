module Enterprise::Conversation
  attr_accessor :captain_activity_reason, :captain_activity_reason_type

  def dispatch_captain_inference_resolved_event
    dispatch_captain_inference_event(Events::Types::CONVERSATION_CAPTAIN_INFERENCE_RESOLVED)
  end

  def dispatch_captain_inference_handoff_event
    dispatch_captain_inference_event(Events::Types::CONVERSATION_CAPTAIN_INFERENCE_HANDOFF)
  end

  def list_of_keys
    super + %w[sla_policy_id]
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

  # Include select additional_attributes keys (call related) for update events
  def allowed_keys?
    return true if super

    attrs_change = previous_changes['additional_attributes']
    return false unless attrs_change.is_a?(Array) && attrs_change[1].is_a?(Hash)

    changed_attr_keys = attrs_change[1].keys
    changed_attr_keys.intersect?(%w[call_status])
  end

  private

  def dispatch_captain_inference_event(event_name)
    dispatcher_dispatch(event_name)
  end
end
