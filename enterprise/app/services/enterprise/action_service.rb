module Enterprise::ActionService
  def add_sla(sla_policy_id)
    sla_policy = @account.sla_policies.find(sla_policy_id.first)
    Rails.logger.info "SLA:: Adding SLA #{sla_policy.id} to conversation: #{@conversation.id}"
    @conversation.update!(sla_policy_id: sla_policy.id)
    create_applied_sla(sla_policy)
  end

  def create_applied_sla(sla_policy)
    Rails.logger.info "SLA:: Creating Applied SLA for conversation: #{@conversation.id}"
    AppliedSla.create!(
      account_id: @conversation.account_id,
      sla_policy_id: sla_policy.id,
      conversation_id: @conversation.id,
      sla_status: 'active'
    )
  end
end
