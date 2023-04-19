module ActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def create_activity
    user_name = Current.user.name if Current.user.present?
    status_change_activity(user_name) if saved_change_to_status?
    priority_change_activity(user_name) if saved_change_to_priority?
    create_label_change(activity_message_ownner(user_name)) if saved_change_to_label_list?
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

  def priority_change_activity(user_name)
    old_priority, new_priority = previous_changes.values_at('priority')[0]
    return unless old_priority.present? || new_priority.present?

    change_type = get_priority_change_type(old_priority, new_priority)

    user = if Current.executed_by.instance_of?(AutomationRule)
             'Automation System'
           else
             user_name
           end

    content = I18n.t("conversations.activity.priority.#{change_type}", user_name: user, new_priority: new_priority, old_priority: old_priority)

    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def get_priority_change_type(old_priority, new_priority)
    case [old_priority.present?, new_priority.present?]
    when [true, true] then 'updated'
    when [false, true] then 'added'
    when [true, false] then 'removed'
    end
  end

  def activity_message_params(content)
    { account_id: account_id, inbox_id: inbox_id, message_type: :activity, content: content }
  end

  def create_label_added(user_name, labels = [])
    create_label_change_activity('added', user_name, labels)
  end

  def create_label_removed(user_name, labels = [])
    create_label_change_activity('removed', user_name, labels)
  end

  def create_label_change_activity(change_type, user_name, labels = [])
    return unless labels.size.positive?

    content = I18n.t("conversations.activity.labels.#{change_type}", { user_name: user_name, labels: labels.join(', ') })
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def create_muted_message
    create_mute_change_activity('muted')
  end

  def create_unmuted_message
    create_mute_change_activity('unmuted')
  end

  def create_mute_change_activity(change_type)
    return unless Current.user

    content = I18n.t("conversations.activity.#{change_type}", { user_name: Current.user.name })
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
end
