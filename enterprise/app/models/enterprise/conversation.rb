module Enterprise::Conversation
  def list_of_keys
    super + %w[sla_policy_id]
  end
end
