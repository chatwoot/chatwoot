module SlaActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def create_sla_change_activity(change_type, user_name)
    return unless %w[added removed updated].include?(change_type)

    params = activity_message_params("sla.#{change_type}", user_name: user_name, sla_name: sla_policy_name, **activity_actor_params)
    ::Conversations::ActivityMessageJob.perform_later(self, params)
  end

  def sla_policy_name
    SlaPolicy.find_by(id: sla_policy_id)&.name || ''
  end

  def determine_sla_change_type
    sla_policy_id_before, sla_policy_id_after = previous_changes[:sla_policy_id]

    if sla_policy_id_before.nil? && sla_policy_id_after.present?
      'added'
    elsif sla_policy_id_before.present? && sla_policy_id_after.nil?
      'removed'
    end
  end
end
