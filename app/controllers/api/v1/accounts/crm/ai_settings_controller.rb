class Api::V1::Accounts::Crm::AiSettingsController < Api::V1::Accounts::Crm::BaseController
  before_action :ensure_crm_ai_enabled
  before_action :fetch_pipeline

  def show
    authorize @pipeline, :manage_ai?
    @ai_settings = Crm::Ai::SettingsPresenter.new(pipeline: @pipeline).perform
  end

  def update
    authorize @pipeline, :manage_ai?
    @pipeline = Crm::Ai::SettingsUpdater.new(
      pipeline: @pipeline,
      params: ai_settings_params,
      stage_criteria: stage_criteria_params,
      stage_handoff: stage_handoff_params
    ).perform
    @ai_settings = Crm::Ai::SettingsPresenter.new(pipeline: @pipeline.reload).perform
    render :show
  end

  private

  def fetch_pipeline
    @pipeline = policy_scope(::Crm::Pipeline).find(params[:pipeline_id])
  end

  def ai_settings_params
    parameter_set(:ai_settings).permit(
      :enabled, :auto_move_enabled, :attribute_extraction_enabled, :callback_enabled, :callback_mode,
      :stale_hours,
      auto_followup: [
        :enabled, :trigger_idle_hours, :max_touches, :tone_instructions,
        { intervals_hours: [], quiet_hours: [:start, :end, :tz] }
      ],
      handoff: [
        :enabled, :mode, :selector_mode, :handoff_mode, :trigger, :prefer_online, :pickup_threshold_seconds,
        :escalation_user_id, :pool_type, :pool_id, :renotify_after_seconds, :escalation_action
      ]
    )
  end

  def stage_criteria_params
    parameter_set(:stage_criteria).permit!.to_h
  end

  def stage_handoff_params
    params.fetch(:stage_handoff, {}).permit!.to_h
  end
end
