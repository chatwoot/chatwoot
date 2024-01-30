class ActionService
  def add_sla(sla_policy)
    @conversation.update!(sla_policy_id: sla_policy.id)
  end
end
