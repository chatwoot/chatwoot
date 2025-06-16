module Enterprise::AutomationRule
  # FIXME: super class doesn't have conditions_attributes and actions_attributes methods
  def conditions_attributes
    super + %w[sla_policy_id]
  end

  def actions_attributes
    super + %w[add_sla]
  end
end
