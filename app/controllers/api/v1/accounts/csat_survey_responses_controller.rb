class Api::V1::Accounts::CsatSurveyResponsesController < Api::V1::Accounts::BaseController
  include DateRangeHelper

  RESULTS_PER_PAGE = 25

  before_action :check_authorization
  before_action :csat_survey_responses, only: [:index]

  def index; end

  private

  def csat_survey_responses
    @csat_survey_responses = Current.account.csat_survey_responses
    @csat_survey_responses = @csat_survey_responses.where(created_at: range) if range.present?
    @csat_survey_responses.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
