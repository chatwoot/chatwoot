module AssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    before_save :ensure_assignee_is_from_team
    before_create :auto_assign_from_contact_consultant
    after_commit :notify_assignment_change, :process_assignment_changes
  end

  private

  def ensure_assignee_is_from_team
    return unless team_id_changed?

    validate_current_assignee_team
    self.assignee ||= find_assignee_from_team
  end

  def validate_current_assignee_team
    self.assignee_id = nil if team&.members&.exclude?(assignee)
  end

  def find_assignee_from_team
    return if team&.allow_auto_assign.blank?

    team_members_with_capacity = inbox.member_ids_with_assignment_capacity & team.members.ids
    ::AutoAssignment::AgentAssignmentService.new(conversation: self, allowed_agent_ids: team_members_with_capacity).find_assignee
  end

  def notify_assignment_change
    {
      ASSIGNEE_CHANGED => -> { saved_change_to_assignee_id? },
      TEAM_CHANGED => -> { saved_change_to_team_id? }
    }.each do |event, condition|
      condition.call && dispatcher_dispatch(event, previous_changes)
    end
  end

  def process_assignment_changes
    process_assignment_activities
    auto_assign_contact_consultant
  end

  def process_assignment_activities
    user_name = Current.user.name if Current.user.present?
    if saved_change_to_team_id?
      create_team_change_activity(user_name)
    elsif saved_change_to_assignee_id?
      create_assignee_change_activity(user_name)
    end
  end

  def self_assign?(assignee_id)
    assignee_id.present? && Current.user&.id == assignee_id
  end

  def auto_assign_from_contact_consultant
    return if assignee_id.present?
    return unless respond_to?(:contact) && contact.present?
    return if contact.consultant_id.blank?

    self.assignee_id = contact.consultant_id
  end

  def auto_assign_contact_consultant
    return unless saved_change_to_assignee_id?
    return if assignee_id.blank?
    return unless respond_to?(:contact) && contact.present?

    account_user = account.account_users.find_by(user_id: assignee_id)
    return if account_user&.custom_role_id.blank?

    consultant_role = account.custom_roles.find_by(name: 'Consultor(a)')
    return unless consultant_role
    return unless account_user.custom_role_id == consultant_role.id

    return if contact.consultant_id.present?

    contact.update!(consultant_id: assignee_id)
  end
end
