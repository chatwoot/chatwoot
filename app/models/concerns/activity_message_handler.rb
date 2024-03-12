# rubocop:disable Metrics/ModuleLength
module ActivityMessageHandler
  extend ActiveSupport::Concern

  include PriorityActivityMessageHandler
  include LabelActivityMessageHandler
  include SlaActivityMessageHandler

  private

  def create_activity
    user_name = determine_user_name

    handle_status_change(user_name)
    handle_priority_change(user_name)
    handle_label_change(user_name)
    handle_sla_policy_change(user_name)
  end

  def determine_user_name
    Current.user&.name
  end

  def handle_status_change(user_name)
    return unless saved_change_to_status?

    status_change_activity(user_name)
  end

  def handle_priority_change(user_name)
    return unless saved_change_to_priority?

    priority_change_activity(user_name)
  end

  def handle_label_change(user_name)
    return unless saved_change_to_label_list?

    create_label_change(activity_message_ownner(user_name))
  end

  def handle_sla_policy_change(user_name)
    return unless saved_change_to_sla_policy_id?

    sla_change_type = determine_sla_change_type
    create_sla_change_activity(sla_change_type, activity_message_ownner(user_name))
  end

  def status_change_activity(user_name)
    content = if Current.executed_by.present?
                automation_status_change_activity_content
              else
                user_status_change_activity_content(user_name)
              end

    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def user_status_change_activity_content(user_name)
    if user_name
      I18n.t("conversations.activity.status.#{status}", user_name: user_name)
    elsif Current.contact.present? && resolved?
      I18n.t('conversations.activity.status.contact_resolved', contact_name: Current.contact.name.capitalize)
    elsif resolved?
      I18n.t('conversations.activity.status.auto_resolved', duration: auto_resolve_duration)
    end
  end

  def automation_status_change_activity_content
    if Current.executed_by.instance_of?(AutomationRule)
      I18n.t("conversations.activity.status.#{status}", user_name: 'Automation System')
    elsif Current.executed_by.instance_of?(Contact)
      Current.executed_by = nil
      I18n.t('conversations.activity.status.system_auto_open')
    end
  end

  def activity_message_params(content)
    { account_id: account_id, inbox_id: inbox_id, message_type: :activity, content: content }
  end

  def create_muted_message
    create_mute_change_activity('muted')
  end

  def create_unmuted_message
    create_mute_change_activity('unmuted')
  end

  def create_mute_change_activity(change_type)
    return unless Current.user

    content = I18n.t("conversations.activity.#{change_type}", user_name: Current.user.name)
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def generate_team_change_activity_key
    team = Team.find_by(id: team_id)
    key = team.present? ? 'assigned' : 'removed'
    key += '_with_assignee' if key == 'assigned' && saved_change_to_assignee_id? && assignee
    key
  end

  def generate_team_name_for_activity
    previous_team_id = previous_changes[:team_id][0]
    Team.find_by(id: previous_team_id)&.name if previous_team_id.present?
  end

  def create_team_change_activity(user_name)
    user_name = activity_message_ownner(user_name)
    return unless user_name

    key = generate_team_change_activity_key
    params = { assignee_name: assignee&.name, team_name: team&.name, user_name: user_name }
    params[:team_name] = generate_team_name_for_activity if key == 'removed'
    content = I18n.t("conversations.activity.team.#{key}", **params)

    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def generate_assignee_change_activity_content(user_name)
    params = { assignee_name: assignee&.name, user_name: user_name }.compact
    key = assignee_id ? 'assigned' : 'removed'
    key = 'self_assigned' if self_assign? assignee_id
    I18n.t("conversations.activity.assignee.#{key}", **params)
  end

  def create_assignee_change_activity(user_name)
    user_name = activity_message_ownner(user_name)

    return unless user_name

    content = generate_assignee_change_activity_content(user_name)
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def activity_message_ownner(user_name)
    user_name = 'Automation System' if !user_name && Current.executed_by.present?
    user_name
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
# rubocop:enable Metrics/ModuleLength
