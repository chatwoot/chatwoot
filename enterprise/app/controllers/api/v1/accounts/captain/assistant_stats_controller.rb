class Api::V1::Accounts::Captain::AssistantStatsController < Api::V1::Accounts::BaseController
  before_action -> { authorize(Captain::Assistant, :metrics?) }
  before_action :set_assistant

  def overview
    render json: Captain::AssistantOverviewStatsBuilder.new(@assistant, params[:range], params[:timezone_offset]).metrics
  end

  def overview_summary
    result = Captain::AssistantOverviewSummaryService.new(
      account: Current.account,
      assistant: @assistant,
      range: params[:range],
      timezone_offset: params[:timezone_offset]
    ).perform

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

  def set_assistant
    @assistant = Current.account.captain_assistants.find(params[:assistant_id])
  end
end
