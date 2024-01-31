module SlaActionService
  def add_sla(sla_policy)
    puts self.class
    @conversation.update!(sla_policy_id: sla_policy.id)
  end
end
