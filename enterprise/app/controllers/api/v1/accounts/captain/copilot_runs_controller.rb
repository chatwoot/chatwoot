class Api::V1::Accounts::Captain::CopilotRunsController < Api::V1::Accounts::BaseController
  before_action :set_action_run

  def approve
    return render_disabled unless Current.account.feature_enabled?('copilot_workflows')
    return render_already_decided unless @action_run.approve

    render json: @action_run.approval_card.push_event_data
  end

  def reject
    return render_already_decided unless @action_run.reject(I18n.t('captain.copilot.approval_rejected'))

    render json: @action_run.approval_card.push_event_data
  end

  private

  # Only the agent who asked Copilot for the change can decide it.
  def set_action_run
    @action_run = CopilotRun::Action.find_by!(id: params[:id], account: Current.account, user: Current.user)
  end

  # Turning the feature off rejects a change awaiting approval instead of applying it.
  def render_disabled
    @action_run.reject(I18n.t('captain.copilot_workflows_disabled'))
    render_already_decided(I18n.t('captain.copilot_workflows_disabled'))
  end

  # The saved card lets the panel show what actually happened, e.g. that the change expired.
  def render_already_decided(error = nil)
    @action_run.reload
    error ||= @action_run.expired? ? I18n.t('captain.copilot.approval_expired_notice') : I18n.t('captain.copilot.approval_already_decided')
    render json: { error: error, message: @action_run.approval_card.push_event_data }, status: :unprocessable_content
  end
end
