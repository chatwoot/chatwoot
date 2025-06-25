class Api::V1::Accounts::Captain::CopilotMessagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }
  before_action :set_copilot_thread

  def index
    @copilot_messages = @copilot_thread
                        .copilot_messages
                        .order(created_at: :asc)
                        .page(permitted_params[:page] || 1)
                        .per(1000)
  end

  private

  def set_copilot_thread
    @copilot_thread = Current.account.copilot_threads.find_by!(
      uuid: params[:copilot_thread_id], user_id: Current.user.id
    )
  end

  def permitted_params
    params.permit(:page)
  end
end
