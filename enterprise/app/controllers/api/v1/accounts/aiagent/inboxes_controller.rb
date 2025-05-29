class Api::V1::Accounts::Aiagent::InboxesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Aiagent::Assistant) }

  before_action :set_assistant
  def index
    @inboxes = @assistant.inboxes
  end

  def create
    inbox = Current.account.inboxes.find(assistant_params[:inbox_id])
    @aiagent_inbox = @assistant.aiagent_inboxes.build(inbox: inbox)
    @aiagent_inbox.save!
  end

  def destroy
    @aiagent_inbox = @assistant.aiagent_inboxes.find_by!(inbox_id: permitted_params[:inbox_id])
    @aiagent_inbox.destroy!
    head :no_content
  end

  private

  def set_assistant
    @assistant = account_assistants.find(permitted_params[:assistant_id])
  end

  def account_assistants
    @account_assistants ||= Current.account.aiagent_assistants
  end

  def permitted_params
    params.permit(:assistant_id, :id, :account_id, :inbox_id)
  end

  def assistant_params
    params.require(:inbox).permit(:inbox_id)
  end
end
