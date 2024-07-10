class Api::V1::Accounts::CsatSurveyResponsesController < Api::V1::Accounts::BaseController
  include Sift
  include DateRangeHelper

  RESULTS_PER_PAGE = 25

  before_action :check_authorization
  before_action :set_csat_survey_responses, only: [:index, :metrics, :download, :questions]
  before_action :set_current_page, only: [:index]
  before_action :set_current_page_surveys, only: [:index]
  before_action :set_total_sent_messages_count, only: [:metrics]

  sort_on :created_at, type: :datetime

  def index
    if params[:export_as_parquet]
      file_name = "csat_surveys_#{Time.now.to_i}.parquet"
      Digitaltolk::StoreSurveyResponsesParquetJob.perform_later(@csat_survey_responses.pluck(:id), file_name)

      render json: { file_url: Digitaltolk::SurveyResponsesParquetService.new([], file_name).perform }.to_json and return
    end
  end

  def metrics
    @total_count = @csat_survey_responses.count
    @ratings_count = @csat_survey_responses.group(:rating).count
  end

  def download
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=csat_report.csv'
    render layout: false, template: 'api/v1/accounts/csat_survey_responses/download', formats: [:csv]
  end

  def questions
    @questions = CsatTemplateQuestion.joins(:csat_survey_responses).merge(@csat_survey_responses).reorder('content asc').distinct
    render json: { questions: @questions }
  end

  private

  def set_total_sent_messages_count
    @csat_messages = Current.account.messages.input_csat
    @csat_messages = @csat_messages.where(created_at: range) if range.present?
    @total_sent_messages_count = @csat_messages.count
  end

  def set_csat_survey_responses
    base_query = Current.account.csat_survey_responses.includes([:conversation, :assigned_agent, :contact])
    @csat_survey_responses = filtrate(base_query).filter_by_created_at(range)
                                                 .filter_by_assigned_agent_id(params[:user_ids])
                                                 .filter_by_inbox_id(params[:inbox_id])
                                                 .filter_by_team_id(params[:team_id])
                                                 .filter_by_rating(params[:rating])
                                                 .filter_by_label(params[:label])
                                                 .filter_by_question(params[:question])
  end

  def set_current_page_surveys
    @csat_survey_responses = @csat_survey_responses.page(@current_page).per(RESULTS_PER_PAGE) if params[:page].present?
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
