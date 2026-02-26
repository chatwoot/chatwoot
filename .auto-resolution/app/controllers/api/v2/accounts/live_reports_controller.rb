class Api::V2::Accounts::LiveReportsController < Api::V1::Accounts::BaseController
  before_action :load_conversations, only: [:conversation_metrics, :grouped_conversation_metrics]
  before_action :set_group_scope, only: [:grouped_conversation_metrics]

  before_action :check_authorization

  def conversation_metrics
    render json: {
      open: @conversations.open.count,
      unattended: @conversations.open.unattended.count,
      unassigned: @conversations.open.unassigned.count,
      pending: @conversations.pending.count
    }
  end

  def grouped_conversation_metrics
    count_by_group = @conversations.open.group(@group_scope).count
    unattended_by_group = @conversations.open.unattended.group(@group_scope).count
    unassigned_by_group = @conversations.open.unassigned.group(@group_scope).count

    group_metrics = count_by_group.map do |group_id, count|
      metric = {
        open: count,
        unattended: unattended_by_group[group_id] || 0,
        unassigned: unassigned_by_group[group_id] || 0
      }
      metric[@group_scope] = group_id
      metric
    end

    render json: group_metrics
  end

  private

  def check_authorization
    authorize :report, :view?
  end

  def set_group_scope
    render json: { error: 'invalid group_by' }, status: :unprocessable_entity and return unless %w[
      team_id
      assignee_id
    ].include?(permitted_params[:group_by])

    @group_scope = permitted_params[:group_by]
  end

  def team
    return unless permitted_params[:team_id]

    @team ||= Current.account.teams.find(permitted_params[:team_id])
  end

  def load_conversations
    scope = Current.account.conversations
    scope = scope.where(team_id: team.id) if team.present?
    @conversations = scope
  end

  def permitted_params
    params.permit(:team_id, :group_by)
  end
end
