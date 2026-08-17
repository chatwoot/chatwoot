class Api::V1::Accounts::Captain::AssistantStatsController < Api::V1::Accounts::BaseController
  OVERVIEW_SUMMARY_CACHE_VERSION = 'v1'.freeze
  OVERVIEW_SUMMARY_CACHE_TTL = 1.hour

  before_action -> { authorize(Captain::Assistant, :metrics?) }
  before_action :set_assistant
  before_action :validate_timezone_offset, only: :overview_summary

  def overview
    render json: Captain::AssistantOverviewStatsBuilder.new(@assistant, params[:range], params[:timezone_offset]).metrics
  end

  def overview_summary
    cached_result = Redis::Alfred.get(overview_summary_cache_key)
    result = cached_result ? JSON.parse(cached_result, symbolize_names: true) : generate_overview_summary

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_content
    else
      render json: result
    end
  end

  def resolution_flow
    render json: Captain::AssistantResolutionFlowBuilder.new(@assistant, params[:range], params[:timezone_offset]).build
  end

  def resolution_trend
    render json: Captain::AssistantResolutionTrendStatsBuilder.new(@assistant, params[:range], params[:timezone_offset]).metrics
  end

  private

  def generate_overview_summary
    result = Captain::AssistantOverviewSummaryService.new(
      account: Current.account,
      assistant: @assistant,
      range: params[:range],
      timezone_offset: params[:timezone_offset]
    ).perform

    Redis::Alfred.set(overview_summary_cache_key, result.to_json, ex: OVERVIEW_SUMMARY_CACHE_TTL.to_i) unless result[:error]
    result
  end

  def overview_summary_cache_key
    [
      'captain_assistant_overview_summary',
      OVERVIEW_SUMMARY_CACHE_VERSION,
      Current.account.id,
      @assistant.cache_key_with_version,
      stats_window.range,
      stats_window.timezone,
      Current.account.locale
    ].join(':')
  end

  def stats_window
    @stats_window ||= Captain::AssistantStatsWindow.new(params[:range], params[:timezone_offset])
  end

  def validate_timezone_offset
    head :unprocessable_entity unless stats_window.timezone_offset_valid?
  end

  def set_assistant
    @assistant = Current.account.captain_assistants.find(params[:assistant_id])
  end
end
