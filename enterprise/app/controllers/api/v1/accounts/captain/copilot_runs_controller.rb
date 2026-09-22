class Api::V1::Accounts::Captain::CopilotRunsController < Api::V1::Accounts::BaseController
  before_action :set_run
  before_action :validate_pagination

  rescue_from Copilot::V2::RunService::ActiveRunConflict do |error|
    render json: { error: 'active_run_conflict', message: error.message }, status: :conflict
  end
  rescue_from Copilot::V2::RunService::Unavailable do |error|
    render json: { error: 'execution_unavailable', message: error.message }, status: :forbidden
  end
  rescue_from ArgumentError do |error|
    render json: { error: 'invalid_request', message: error.message }, status: :unprocessable_entity
  end

  def show
    render json: Copilot::V2::RunSerializer.new(@run, page: @page, per_page: @per_page).as_json
  end

  def resume
    Copilot::V2::RunService.new(thread: @thread, user: Current.user).resume(run: @run)
    show
  end

  def cancel
    Copilot::V2::RunService.new(thread: @thread, user: Current.user).cancel(run: @run)
    show
  end

  private

  def set_run
    @thread = Current.account.copilot_threads.find_by!(id: params[:copilot_thread_id], user: Current.user)
    @run = @thread.copilot_runs.find(params[:id])
  end

  def validate_pagination
    @page = pagination_value(:page, 1)
    @per_page = pagination_value(:per_page, 100)
    raise ArgumentError, 'per_page must not exceed 100' if @per_page > 100
  end

  def pagination_value(key, default)
    value = params.fetch(key, default)
    raise ArgumentError, "#{key} must be a positive integer" unless value.to_s.match?(/\A[1-9]\d*\z/)

    value.to_i
  end
end
