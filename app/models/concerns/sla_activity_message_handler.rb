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
end
