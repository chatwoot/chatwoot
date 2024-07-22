class Api::V1::Accounts::MessagesController < Api::V1::Accounts::BaseController
  include Sift
  include DateRangeHelper

  before_action :require_date_range_for_parquet_request, only: [:index]
  before_action :set_messages, only: [:index]
  before_action :set_current_page, only: [:index]
  before_action :set_current_page_messages, only: [:index]

  def index
    if params[:export_as_parquet]
      file_name = "messages_#{Time.now.to_i}.parquet"
      report = ParquetReport::Message.create(
        account_id: Current.account.id, 
        user_id: Current.user&.id, 
        params: params, 
        file_name: file_name
      )
      report.perform_later
      render json: { progress_url: report.progress_url, report_id: report.id, file_url: report.create_empty_file_url }.to_json and return
    end
  end

  private

  def set_messages
    base_query = Current.account.messages.includes(:inbox, :conversation)
    @messages = filtrate(base_query).filter_by_created_at(range)
                                    .filter_by_inbox(params[:inbox_id])
                                    .filter_by_team(params[:team_id])
                                    .filter_by_label(params[:label])
                                    .order(created_at: :desc)
  end

  def set_current_page_messages
    @messages = @messages.page(@current_page).per(RESULTS_PER_PAGE) if params[:page].present?
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
