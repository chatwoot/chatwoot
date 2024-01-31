module Enterprise::ActionService
  def add_sla(sla_policy)
    @conversation.update!(sla_policy_id: sla_policy.id)
    create_applied_sla
  end

  def create_applied_sla
    AppliedSla.create!(
      account: @conversation.account,
      sla_policy: sla_policy,
      conversation: @conversation,
      sla_status: 'active'
    )
  end
end
