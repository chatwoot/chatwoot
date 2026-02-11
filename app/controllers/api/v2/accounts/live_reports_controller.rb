class Api::V2::Accounts::LiveReportsController < Api::V1::Accounts::BaseController
  before_action :load_conversations, only: [:conversation_metrics, :grouped_conversation_metrics]
  before_action :set_group_scope, only: [:grouped_conversation_metrics]

  before_action :check_authorization

  def conversation_metrics
    render json: {
      open: @conversations.open.count,
      unattended: @conversations.open.unattended.count,
      unassigned: @conversations.open.unassigned.count,
      pending: @conversations.pending.count,
      resolved: @conversations.resolved.count
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

  def team_ids
    return [] if permitted_params[:team_ids].blank?

    permitted_params[:team_ids].reject(&:blank?)
  end

  def user_ids
    return [] if permitted_params[:user_ids].blank?

    permitted_params[:user_ids].reject(&:blank?)
  end

  def inbox_ids
    return [] if permitted_params[:inbox_ids].blank?

    permitted_params[:inbox_ids].reject(&:blank?)
  end

  def load_conversations
    scope = Current.account.conversations
    scope = apply_team_filter(scope)
    scope = apply_user_filter(scope)
    scope = apply_inbox_filter(scope)
    @conversations = apply_date_filter(scope)
  end

  def apply_team_filter(scope)
    team_ids.present? ? scope.where(team_id: team_ids) : scope
  end

  def apply_user_filter(scope)
    user_ids.present? ? scope.where(assignee_id: user_ids) : scope
  end

  def apply_inbox_filter(scope)
    inbox_ids.present? ? scope.where(inbox_id: inbox_ids) : scope
  end

  def apply_date_filter(scope)
    return scope unless date_range_present?

    since = Time.zone.at(permitted_params[:since].to_i)
    until_time = Time.zone.at(permitted_params[:until].to_i)
    scope.where(created_at: since..until_time)
  end

  def date_range_present?
    permitted_params[:since].present? && permitted_params[:until].present?
  end

  def permitted_params
    params.permit(:team_id, :group_by, :since, :until, team_ids: [], user_ids: [], inbox_ids: [])
  end
end
