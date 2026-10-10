class Api::V1::Accounts::Captain::CopilotRunsController < Api::V1::Accounts::BaseController
  before_action :set_action_run

  def approve
    return render_disabled unless Current.account.feature_enabled?('copilot_workflows')
    return render_not_pending unless @action_run.approve

    render json: @action_run.receipt
  end

  def reject
    return render_not_pending unless @action_run.reject(I18n.t('captain.copilot.approval_rejected'))

    render json: @action_run.receipt
  end

  private

  # Only the agent who asked Copilot for the change can decide it.
  def set_action_run
    @action_run = CopilotRun.find_by!(id: params[:id], account: Current.account, user: Current.user, kind: 'action')
  end

  # Turning the feature off rejects a pending change instead of applying it.
  def render_disabled
    @action_run.reject(I18n.t('captain.copilot_workflows_disabled'))
    render_not_pending(I18n.t('captain.copilot_workflows_disabled'))
  end

  # The status lets the approval card show what actually happened, e.g. that the change expired.
  def render_not_pending(error = nil)
    status = @action_run.reload.status
    error ||= status == 'expired' ? I18n.t('captain.copilot.approval_expired_notice') : I18n.t('captain.copilot.approval_already_decided')
    render json: { error: error, status: %w[rejected expired].include?(status) ? status : 'approved' }, status: :unprocessable_content
  end
end
