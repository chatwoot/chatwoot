module Enterprise::Conversation
  def list_of_keys
    super + %w[sla_policy_id]
  end

  # Include select additional_attributes keys (call related) for update events
  def allowed_keys?
    return true if super

    attrs_change = previous_changes['additional_attributes']
    return false unless attrs_change.is_a?(Array) && attrs_change[1].is_a?(Hash)

    changed_attr_keys = attrs_change[1].keys
    changed_attr_keys.intersect?(%w[call_status])
  end
end
