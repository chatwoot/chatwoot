class Api::V1::Accounts::Captain::AssistantResponsesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_assistant, only: [:create]
  before_action :set_responses, except: [:create]
  before_action :set_response, only: [:show, :update, :destroy]

  RESULTS_PER_PAGE = 25

  def index
    base_query = @responses
    base_query = base_query.where(assistant_id: permitted_params[:assistant_id]) if permitted_params[:assistant_id].present?
    base_query = base_query.where(document_id: permitted_params[:document_id]) if permitted_params[:document_id].present?
    @responses = base_query.page(permitted_params[:page] || 1).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    @response = Current.account.captain_assistant_responses.new(response_params)
    @response.save!
  end

  def update
    @response.update!(response_params)
  end

  def destroy
    @response.destroy
    head :no_content
  end

  private

  def set_assistant
    @assistant = Current.account.captain_assistants.find_by(id: params[:assistant_id])
  end

  def set_responses
    @responses = Current.account.captain_assistant_responses.includes(:assistant, :document).ordered
  end

  def set_response
    @response = @responses.find(permitted_params[:id])
  end

  def permitted_params
    params.permit(:id, :assistant_id, :page, :document_id)
  end

  def response_params
    params.require(:assistant_response).permit(
      :question,
      :answer,
      :document_id,
      :assistant_id
    )
  end
end
