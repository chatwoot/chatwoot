module Enterprise::Conversation
  private

  # Extend the base list so SLA changes trigger updates in EE
  def list_of_keys
    super + %w[sla_policy_id]
  end

  # In EE, also consider call-related attributes in additional_attributes
  def allowed_keys?
    (
      previous_changes.keys.intersect?(list_of_keys) ||
      (previous_changes['additional_attributes'].present? &&
        previous_changes['additional_attributes'][1].keys.intersect?(%w[conversation_language call_status call_duration]))
    )
  end
end
