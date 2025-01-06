class Api::V1::Accounts::Captain::AssistantResponsesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_assistant
  before_action :set_responses, only: [:index, :show, :update, :destroy]
  before_action :set_response, only: [:show, :update, :destroy]

  def index
    @responses = @responses
                 .includes(:assistant, :document)
                 .ordered
                 .page(params[:page])
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
    @assistant = Current.account.captain_assistants.find(params[:assistant_id])
  end

  def set_responses
    @responses = @assistant.responses
  end

  def set_response
    @response = @responses.find(params[:id])
  end

  def response_params
    params.require(:assistant_response).permit(
      :question,
      :answer,
      :document_id
    ).merge(assistant_id: params[:assistant_id])
  end
end
