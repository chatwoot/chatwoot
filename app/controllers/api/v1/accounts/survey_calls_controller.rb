class Api::V1::Accounts::SurveyCallsController < Api::V1::Accounts::BaseController
  before_action :set_contact
  before_action :set_survey

  def create
    authorize @contact, :show?

    service = SurveyCallService.new(contact: @contact, survey: @survey)
    result = service.perform

    render json: result, status: :ok
  rescue SurveyCallService::ConfigurationError => e
    render json: { error: e.message }, status: :service_unavailable
  rescue SurveyCallService::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue SurveyCallService::RequestError => e
    render json: { error: e.message }, status: :bad_gateway
  end

  private

  def set_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end

  def set_survey
    @survey = Current.account.surveys.find(params[:survey_id])
  end
end
