module Enterprise::ActionService
  def add_sla(sla_policy)
    @conversation.update!(sla_policy_id: sla_policy.id)
    create_applied_sla(sla_policy)
  end

  def create_applied_sla(sla_policy)
    AppliedSla.create!(
      account_id: @conversation.account_id,
      sla_policy_id: sla_policy.id,
      conversation_id: @conversation.id,
      sla_status: 'active'
    )
  end
end
