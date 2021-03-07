class Api::V1::Accounts::ConversationStatusesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization

  def index
    @conversation_statuses = Current.account.conversation_statuses
  end

  def show; end

  def create
    @conversation_status = Current.account.conversation_statuses.create!(permitted_params)
  end

  def permitted_params
    params.require(:conversation_status).permit(:name, :custom)
  end
end
