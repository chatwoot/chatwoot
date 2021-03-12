module AssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    before_save :ensure_assignee_is_from_team
    after_update :notify_assignment_change, :process_assignment_activities
  end

  private

  def ensure_assignee_is_from_team
    return unless team_id_changed?

    ensure_current_assignee_team
    self.assignee_id ||= find_team_assignee_id_for_inbox if team&.allow_auto_assign.present?
  end

  def ensure_current_assignee_team
    self.assignee_id = nil if team&.members&.exclude?(assignee)
  end

  def find_team_assignee_id_for_inbox
    members = inbox.members.ids & team.members.ids
    # TODO: User round robin to determine the next agent instead of using sample
    members.sample
  end

  def notify_assignment_change
    {
      ASSIGNEE_CHANGED => -> { saved_change_to_assignee_id? },
      TEAM_CHANGED => -> { saved_change_to_team_id? }
    }.each do |event, condition|
      condition.call && dispatcher_dispatch(event)
    end
  end

  def process_assignment_activities
    user_name = Current.user.name if Current.user.present?
    if saved_change_to_team_id?
      create_team_change_activity(user_name)
    elsif saved_change_to_assignee_id?
      create_assignee_change_activity(user_name)
    end
  end

  def generate_team_change_activity_key
    key = team_id ? 'assigned' : 'removed'
    key += '_with_assignee' if key == 'assigned' && saved_change_to_assignee_id? && assignee
    key
  end

  def create_team_change_activity(user_name)
    return unless user_name

    key = generate_team_change_activity_key
    params = { assignee_name: assignee&.name, team_name: team&.name, user_name: user_name }
    if key == 'removed'
      previous_team_id = previous_changes[:team_id][0]
      params[:team_name] = Team.find_by(id: previous_team_id)&.name if previous_team_id.present?
    end
    content = I18n.t("conversations.activity.team.#{key}", **params)

    messages.create(activity_message_params(content))
  end

  def create_assignee_change_activity(user_name)
    return unless user_name

    params = { assignee_name: assignee&.name, user_name: user_name }.compact
    key = assignee_id ? 'assigned' : 'removed'
    key = 'self_assigned' if self_assign? assignee_id
    content = I18n.t("conversations.activity.assignee.#{key}", **params)

    messages.create(activity_message_params(content))
  end
end
