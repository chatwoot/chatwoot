module SlaActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def create_sla_change_activity(change_type, user_name)
    content = case change_type
              when 'added'
                I18n.t('conversations.activity.sla.added', user_name: user_name, sla_name: sla_policy_name)
              when 'removed'
                I18n.t('conversations.activity.sla.removed', user_name: user_name, sla_name: sla_policy_name)
              when 'updated'
                I18n.t('conversations.activity.sla.updated', user_name: user_name, sla_name: sla_policy_name)
              end
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
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
