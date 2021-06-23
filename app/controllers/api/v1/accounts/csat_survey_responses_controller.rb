class Api::V1::Accounts::CsatSurveyResponsesController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 25

  before_action :check_authorization
 
  def index
    @csat_survey_responses = csat_survey_responses
  end

  private

  def csat_survey_responses
    Current.account.csat_survey_responses.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
