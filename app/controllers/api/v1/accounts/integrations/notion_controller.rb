class Api::V1::Accounts::Integrations::NotionController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, only: [:destroy, :issue_tracker, :update_issue_tracker, :validate_issue_tracker]

  def destroy
    @hook.destroy!
    head :ok
  end

  def issue_tracker
    render json: issue_tracker_settings, status: :ok
  end

  def update_issue_tracker
    updated_settings = @hook.settings.to_h.merge(
      'issue_tracker' => permitted_issue_tracker_params.to_h
    )
    @hook.update!(settings: updated_settings)

    render json: issue_tracker_settings, status: :ok
  end

  def validate_issue_tracker
    response = issue_tracker_config_service.validate(permitted_issue_tracker_params[:data_source_id])
    if response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: response[:data], status: :ok
    end
  end

  private

  def issue_tracker_settings
    @hook.settings.to_h['issue_tracker'] || {}
  end

  def issue_tracker_config_service
    Integrations::Notion::IssueTrackerConfigService.new(hook: @hook)
  end

  def permitted_issue_tracker_params
    params.permit(
      :data_source_id,
      :title_property,
      :description_property,
      :assignee_property,
      :project_property,
      :status_property,
      :priority_property,
      :label_property
    )
  end

  def fetch_hook
    @hook = Integrations::Hook.where(account: Current.account).find_by!(app_id: 'notion')
  end
end
