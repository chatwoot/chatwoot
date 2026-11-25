# Inbox setting drop_assignee_outside_team_on_reopen: when a customer's message reopens a
# conversation, an assignee who is no longer a member of the conversation's team is
# dropped and the conversation goes back to Unassigned, keeping its team. Every automatic
# picker draws only from the conversation team's members, so none of them can hand it
# back to the agent who was dropped.
module ReopenTeamAssigneeHandler
  extend ActiveSupport::Concern

  included do
    # Included before AssignmentHandler and AutoAssignmentHandler, so the takeover guard
    # and the legacy auto-assignment in this same save see the owner this settles.
    before_save :drop_assignee_outside_team, if: -> { @reopen_team_check_assignee_id }
  end

  # Called by the customer's message right before the status save that reopens the
  # conversation; the decision is taken inside that save, under the row lock.
  def check_assignee_team_on_reopen
    return unless inbox.drop_assignee_outside_team_on_reopen?

    @reopen_team_check_assignee_id = assignee_id
  end

  private

  # An agent can reassign, change the team or reopen the conversation after the customer's
  # message read it and before this save. Judging the locked row leaves their action alone:
  # the assignee is dropped only while the row still holds the one judged and is still
  # resolved or snoozed, and only against the team the row holds now.
  def drop_assignee_outside_team
    judged_id = @reopen_team_check_assignee_id
    @reopen_team_check_assignee_id = nil
    @reopen_team_unassignment = nil
    owner_id, persisted_status, persisted_team_id = self.class.lock.where(id: id).pick(:assignee_id, :status, :team_id)
    return unless owner_id == judged_id && %w[resolved snoozed].include?(persisted_status)

    # The legacy auto-assignment later in this save picks from this instance's team, which has
    # to be the one the assignee was judged against.
    self.team_id = persisted_team_id
    clear_attribute_changes([:team_id])
    return if team.blank? || team.team_members.exists?(user_id: judged_id)

    @reopen_team_unassignment = { assignee_name: assignee.name, team_name: team.name }
    self.assignee = nil
  end

  def reopen_team_unassignment?
    @reopen_team_unassignment.present?
  end

  # Runs with no user and no executed_by (a customer message did it), which would make the
  # generic activity path drop the line; the reason is the point of it anyway.
  def create_reopen_team_unassignment_activity
    content = I18n.t('conversations.activity.assignee.removed_not_in_conversation_team', **@reopen_team_unassignment, locale: account.locale)
    @reopen_team_unassignment = nil
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content))
  end
end
