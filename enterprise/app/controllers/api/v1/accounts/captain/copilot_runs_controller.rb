class Api::V1::Accounts::Captain::CopilotRunsController < Api::V1::Accounts::BaseController
  before_action :set_action_run

  def approve
    return render_already_decided unless @action_run.approve

    render json: @action_run.receipt
  end

  def reject
    return render_already_decided unless @action_run.reject(I18n.t('captain.copilot.approval_rejected'))

    render json: @action_run.receipt
  end

  private

  # Only the agent who asked Copilot for the change can decide it.
  def set_action_run
    @action_run = CopilotRun.find_by!(id: params[:id], account: Current.account, user: Current.user, kind: 'action')
  end

  def render_already_decided
    render json: { error: I18n.t('captain.copilot.approval_already_decided') }, status: :unprocessable_content
  end
end
