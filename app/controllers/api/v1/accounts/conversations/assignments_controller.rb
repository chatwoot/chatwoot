class Api::V1::Accounts::Conversations::AssignmentsController < Api::V1::Accounts::Conversations::BaseController
  # assigns agent/team to a conversation
  def create
    render json: { error: I18n.t('errors.assignment.permission') }, status: :forbidden and return unless permission?

    if params.key?(:assignee_id)
      set_agent
    elsif params.key?(:team_id)
      set_team
    else
      render json: nil
    end
  end

  private

  def set_agent
    @agent = Current.account.users.find_by(id: params[:assignee_id])
    @conversation.assignee = @agent
    @conversation.save!
    render_agent
  end

  def render_agent
    if @agent.nil?
      render json: nil
    else
      render partial: 'api/v1/models/agent', formats: [:json], locals: { resource: @agent }
    end
  end

  def set_team
    @team = Current.account.teams.find_by(id: params[:team_id])
    @conversation.update!(team: @team)
    render json: @team
  end

  def permission?
    return true if Current.account.no_restriction?

    return restriction? if Current.account.restriction?

    # TODO: check the option of change_under_control
    false
  end

  def restriction?
    # everyone can assign to themselves if the conversation doesn't have assignee yet
    return true if @conversation.assignee.blank? && params[:assignee_id].present? && Current.user.id == params[:assignee_id].to_i

    # admin user, or leader of the team of current inbox can change
    return true if Current.user.administrator? || Current.user == @conversation.inbox.team&.leader

    false
  end
end
