module Enterprise::AutomationRule
  def conditions_attributes
    super + %w[sla_policy_id]
  end

  def actions_attributes
    super + %w[add_sla]
  end
end
