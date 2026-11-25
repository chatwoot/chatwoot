module AssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    before_save :ensure_assignee_is_from_team
    # Declared after the team callback on purpose: that one can null the assignee
    # when the new team excludes them, and the guard has to see the final value.
    before_save :ensure_assignment_not_taken, if: :assignee_id_changed?
    before_save :ensure_assignment_within_working_hours, if: :assignee_id_changed?
    after_commit :notify_assignment_change, :process_assignment_changes
  end

  private

  # The conversation belongs to whoever claimed it first. Only the current
  # assignee and administrators get to change that; every other agent is turned
  # away with a 409.
  def ensure_assignment_not_taken
    return if new_record?
    return unless inbox.prevent_assignment_takeover?

    current_assignee_id = locked_assignee_id
    return if current_assignee_id.blank? || current_assignee_id == assignee_id
    return if assignment_change_allowed?(current_assignee_id)

    raise CustomExceptions::Conversation::AlreadyAssigned.new(
      agent_name: account.users.find_by(id: current_assignee_id)&.available_name
    )
  end

  # Locks the row for the rest of the surrounding save transaction and reads the
  # owner back from the database. `assignee_id_was` would be cheaper but it is
  # the value *this instance* loaded, and two agents claiming the same free
  # conversation at the same instant both load it as nil: each would clear the
  # check and the second write would silently win, which is the exact race this
  # feature exists to close. Blocking here makes the second transaction wait for
  # the first to commit and then see its owner. Same approach as
  # Voice::Provider::Twilio::ConferenceService#claim_call!.
  def locked_assignee_id
    self.class.lock.where(id: id).pick(:assignee_id)
  end

  # `Current.user` is the same discriminator `process_assignment_activities`
  # already relies on to tell a human action apart from an automated one:
  # round-robin, automation rules (AsyncDispatcher -> job) and voice webhooks
  # reach this callback with it unset and pass straight through. BulkActionsJob
  # and Macros::ExecutionService set it deliberately, because they *are* human
  # actions, which is why they are guarded too.
  #
  # The `is_a?(User)` test is not just a nil check: a bot-authenticated request
  # puts an AgentBot in `Current.user`, and its id lives in a different sequence
  # than `users.id`, so comparing the two would match by coincidence.
  def assignment_change_allowed?(current_assignee_id)
    # Dropping the assignee on reopen hands the conversation to nobody, so it is not a takeover,
    # whoever is in Current.user (an API inbox can post the customer's message with an agent token).
    return true if reopen_team_unassignment? || reopen_agent_bot_handoff?
    return true unless Current.user.is_a?(User)
    return true if Current.user.id == current_assignee_id

    account.account_users.exists?(user_id: Current.user.id, role: :administrator)
  end

  # An inbox that holds assignment until it opens turns away every agent who
  # assigns one of its conversations while it is closed, to themselves or to
  # someone else. Releasing a conversation is not a claim, and administrators
  # keep assigning at any hour. Automated assignment has no `Current.user` and
  # is held back where it starts instead (`AutoAssignmentHandler`,
  # `AutoAssignment::AssignmentService`), except automation rules and API
  # integrations, which an administrator set up on purpose.
  def ensure_assignment_within_working_hours
    return if new_record? || assignee_id.blank?
    return unless Current.user.is_a?(User)
    return unless inbox.assignment_closed?
    return if account.account_users.exists?(user_id: Current.user.id, role: :administrator)

    raise CustomExceptions::Conversation::OutsideWorkingHours.new({})
  end

  def ensure_assignee_is_from_team
    return unless team_id_changed?
    return if ai_assignee_type.present?

    validate_current_assignee_team
    self.assignee ||= find_assignee_from_team
  end

  def validate_current_assignee_team
    self.assignee_id = nil if team&.members&.exclude?(assignee)
  end

  def find_assignee_from_team
    return if team&.allow_auto_assign.blank?
    return if inbox.assignment_closed?

    team_members_with_capacity = inbox.member_ids_with_assignment_capacity & team.members.ids
    ::AutoAssignment::AgentAssignmentService.new(conversation: self, allowed_agent_ids: team_members_with_capacity).find_assignee
  end

  def notify_assignment_change
    {
      ASSIGNEE_CHANGED => lambda {
        saved_change_to_assignee_id? || saved_change_to_assignee_agent_bot_id? || saved_change_to_ai_assignee_type?
      },
      TEAM_CHANGED => -> { saved_change_to_team_id? }
    }.each do |event, condition|
      condition.call && dispatcher_dispatch(event, previous_changes)
    end
  end

  def process_assignment_changes
    process_assignment_activities
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
end
