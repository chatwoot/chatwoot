# Runs conversation writes that can hand a human an open conversation through the assignee's
# max_open_conversations check, see Conversations::AssignmentRulesService#enforce!
module ConversationAssignmentLimitConcern
  extend ActiveSupport::Concern

  included do
    rescue_from CustomExceptions::ConversationAssignmentNotAllowed, with: :render_assignment_not_allowed
  end

  private

  def enforce_assignment_limit(assignee, &)
    Conversations::AssignmentRulesService.new(account: Current.account, assignee: assignee).enforce!(&)
  end

  def requested_assignee
    Current.account.users.find_by(id: params[:assignee_id]) if params[:assignee_id].present?
  end

  # The human who would hold the conversation once it is open, see handle_human_open
  def reopening_assignee
    return unless Current.user.is_a?(User)

    Current.user.agent? ? Current.user : @conversation.assignee
  end

  def handle_human_open
    @conversation.with_lock do
      @conversation.ai_assignee = nil
      @conversation.assignee = Current.user if Current.user.agent?
      @conversation.save!
    end
  end

  def render_assignment_not_allowed(error)
    render_could_not_create_error(error.message)
  end
end
