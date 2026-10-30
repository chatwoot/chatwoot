class Captain::Copilot::Actions::ApplySla < Captain::Copilot::Actions::BaseAction
  NAME = 'apply_sla'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Apply an SLA policy to each conversation. Arguments: sla_policy_id, the ID of an SLA policy in the account.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[sla_policy_id],
    properties: { sla_policy_id: { type: 'integer', minimum: 1 } }
  }.deep_stringify_keys.freeze

  # The same write as the dashboard's SLA menu. Saving the policy starts its timers on the conversation.
  def perform(conversation)
    return :skipped if conversation.sla_policy_id == sla_policy.id

    conversation.update!(sla_policy: sla_policy)
    :applied
  end

  def card(_ids)
    super.merge(values: { sla: sla_policy.name })
  end

  private

  def sla_policy
    @sla_policy ||= @account.sla_policies.find_by(id: @arguments['sla_policy_id'])
  end

  def validate!
    raise ArgumentError, 'SLA policies are not enabled for this account' unless @account.feature_enabled?('sla')
    return if sla_policy

    policies = @account.sla_policies.order(:name).map { |policy| "#{policy.name} (ID #{policy.id})" }
    raise ArgumentError, "No SLA policy with ID #{@arguments['sla_policy_id']}. SLA policies: #{policies.join(', ').presence || 'none'}"
  end
end
