module AssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    before_save :ensure_assignee_is_from_team
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
    Rails.logger.info "[ASSIGNMENT_HANDLER] 📢 notify_assignment_change called for conversation #{id}"
    Rails.logger.info "[ASSIGNMENT_HANDLER] Current.user: #{Current.user&.id} (#{Current.user&.name})"
    Rails.logger.info "[ASSIGNMENT_HANDLER] Current.executed_by: #{Current.executed_by.inspect}"
    Rails.logger.info "[ASSIGNMENT_HANDLER] saved_change_to_assignee_id?: #{saved_change_to_assignee_id?}"
    Rails.logger.info "[ASSIGNMENT_HANDLER] saved_change_to_team_id?: #{saved_change_to_team_id?}"

    {
      ASSIGNEE_CHANGED => -> { saved_change_to_assignee_id? },
      TEAM_CHANGED => -> { saved_change_to_team_id? }
    }.each do |event, condition|
      if condition.call
        Rails.logger.info "[ASSIGNMENT_HANDLER] 🔔 Dispatching event: #{event}"
        dispatcher_dispatch(event, previous_changes)
      end
    end
  end

  def process_assignment_changes
    Rails.logger.info "[ASSIGNMENT_HANDLER] 🔄 process_assignment_changes called for conversation #{id}"
    process_assignment_activities
  end

  def process_assignment_activities
    Rails.logger.info "[ASSIGNMENT_HANDLER] 📝 process_assignment_activities called for conversation #{id}"
    Rails.logger.info "[ASSIGNMENT_HANDLER] Current.user: #{Current.user&.id} (#{Current.user&.name})"
    Rails.logger.info "[ASSIGNMENT_HANDLER] Current.executed_by: #{Current.executed_by.inspect}"

    user_name = Current.user.name if Current.user.present?

    if saved_change_to_team_id?
      Rails.logger.info "[ASSIGNMENT_HANDLER] 🔄 Team changed for conversation #{id}: #{saved_changes['team_id']}"
      create_team_change_activity(user_name)
    elsif saved_change_to_assignee_id?
      assignee_change = saved_changes['assignee_id']
      Rails.logger.info "[ASSIGNMENT_HANDLER] 👤 Assignee changed for conversation #{id}: #{assignee_change[0]} → #{assignee_change[1]}"
      Rails.logger.info "[ASSIGNMENT_HANDLER] User name for activity: #{user_name || 'SYSTEM/AUTOMATION'}"
      create_assignee_change_activity(user_name)
    else
      Rails.logger.info '[ASSIGNMENT_HANDLER] ⚠️  No team or assignee changes detected'
    end
  end

  def self_assign?(assignee_id)
    assignee_id.present? && Current.user&.id == assignee_id
  end
end
