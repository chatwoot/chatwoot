class Api::V1::Accounts::AgentScoresController < Api::V1::Accounts::BaseController
  include DateRangeHelper
  before_action :require_date_range_for_parquet_request, only: [:index]

  def index
    if export_as_parquet?
      file_name = "agent_scores_#{Time.now.to_i}.parquet"
      report = ParquetReport::AgentScore.create(
        account_id: Current.account.id,
        user_id: Current.user&.id,
        params: params,
        file_name: file_name
      )
      Digitaltolk::ProcessAgentScoreParquetJob.perform_later(report)
      render json: { progress_url: report.progress_url, report_id: report.id, file_url: report.create_empty_file_url }.to_json and return
    else
      @agent_scores = Current.account.smart_actions.outgoing_message_score.filter_by_created_at(range)
    end
  end
end