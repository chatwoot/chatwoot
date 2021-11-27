module ActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def create_activity
    user_name = Current.user.name if Current.user.present?
    status_change_activity(user_name) if saved_change_to_status?
    create_label_change(user_name) if saved_change_to_label_list?
  end

  def status_change_activity(user_name)
    create_status_change_message(user_name)
  end

  def activity_message_params(content)
    { account_id: account_id, inbox_id: inbox_id, message_type: :activity, content: content }
  end

  def create_status_change_message(user_name)
    content = if user_name
                I18n.t("conversations.activity.status.#{status}", user_name: user_name)
              elsif resolved?
                I18n.t('conversations.activity.status.auto_resolved', duration: auto_resolve_duration)
              end

    Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def create_label_added(user_name, labels = [])
    return unless labels.size.positive?

    params = { user_name: user_name, labels: labels.join(', ') }
    content = I18n.t('conversations.activity.labels.added', **params)

    Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def create_label_removed(user_name, labels = [])
    return unless labels.size.positive?

    params = { user_name: user_name, labels: labels.join(', ') }
    content = I18n.t('conversations.activity.labels.removed', **params)

    Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def create_muted_message
    return unless Current.user

    params = { user_name: Current.user.name }
    content = I18n.t('conversations.activity.muted', **params)

    Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def create_unmuted_message
    return unless Current.user

    params = { user_name: Current.user.name }
    content = I18n.t('conversations.activity.unmuted', **params)

    Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def generate_team_change_activity_key
    key = team_id ? 'assigned' : 'removed'
    key += '_with_assignee' if key == 'assigned' && saved_change_to_assignee_id? && assignee
    key
  end

  def generate_team_name_for_activity
    previous_team_id = previous_changes[:team_id][0]
    Team.find_by(id: previous_team_id)&.name if previous_team_id.present?
  end

  def create_team_change_activity(user_name)
    return unless user_name

    key = generate_team_change_activity_key
    params = { assignee_name: assignee&.name, team_name: team&.name, user_name: user_name }
    params[:team_name] = generate_team_name_for_activity if key == 'removed'
    content = I18n.t("conversations.activity.team.#{key}", **params)

    Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def generate_assignee_change_activity_content(user_name)
    params = { assignee_name: assignee&.name, user_name: user_name }.compact
    key = assignee_id ? 'assigned' : 'removed'
    key = 'self_assigned' if self_assign? assignee_id
    I18n.t("conversations.activity.assignee.#{key}", **params)
  end

  def create_assignee_change_activity(user_name)
    return unless user_name

    content = generate_assignee_change_activity_content(user_name)
    Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end
end
