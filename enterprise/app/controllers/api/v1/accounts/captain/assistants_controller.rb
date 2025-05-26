class Api::V1::Accounts::Captain::AssistantsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_assistant, only: [:show, :update, :destroy, :playground]

  def index
    @assistants = account_assistants.ordered
  end

  def show; end

  def create
    @assistant = account_assistants.create!(assistant_params)
  end

  def update
    @assistant.update!(assistant_params)
  end

  def destroy
    @assistant.destroy
    head :no_content
  end

  def playground
    response = Captain::Llm::AssistantChatService.new(assistant: @assistant).generate_response(
      params[:message_content],
      message_history
    )

    render json: response
  end

  private

  def set_assistant
    @assistant = account_assistants.find(params[:id])
  end

  def account_assistants
    @account_assistants ||= Captain::Assistant.for_account(Current.account.id)
  end

  def assistant_params
    params.require(:assistant).permit(:name, :description,
                                      config: [
                                        :product_name, :feature_faq, :feature_memory,
                                        :welcome_message, :handoff_message, :resolution_message,
                                        :instructions, :temperature
                                      ])
  end

  def playground_params
    params.require(:assistant).permit(:message_content, message_history: [:role, :content])
  end

  def message_history
    (playground_params[:message_history] || []).map { |message| { role: message[:role], content: message[:content] } }
  end
end
