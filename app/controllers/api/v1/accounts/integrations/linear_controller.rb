class Api::V1::Accounts::Integrations::LinearController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: [:list]

  def list
    issues = linear_processor_service.list_issues
    render json: issues, status: :ok
  end

  private

  def linear_processor_service
    Integrations::Linear::ProcessorService.new(account: Current.account, conversation: @conversation)
  end

  def permitted_params
    params.permit(:conversation_id)
  end

  def fetch_conversation
    @conversation = Current.account.conversations.find_by!(display_id: permitted_params[:conversation_id])
  end
end
