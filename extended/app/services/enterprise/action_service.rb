module Enterprise::ActionService
  def add_sla(sla_policy_id)
    return if sla_policy_id.blank?

    sla_policy = @account.sla_policies.find_by(id: sla_policy_id.first)
    return if sla_policy.nil?
    return if @conversation.sla_policy.present?

    Rails.logger.info "SLA:: Adding SLA #{sla_policy.id} to conversation: #{@conversation.id}"
    @conversation.update!(sla_policy_id: sla_policy.id)
  end
end
