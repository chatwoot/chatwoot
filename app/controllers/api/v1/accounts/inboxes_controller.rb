class Api::V1::Accounts::InboxesController < Api::BaseController
  before_action :check_authorization
  before_action :fetch_inbox, only: [:destroy, :update]

  def index
    @inboxes = policy_scope(current_account.inboxes)
  end

  def destroy
    @inbox.destroy
    head :ok
  end

  def update
    @inbox.update(inbox_update_params)
  end

  private

  def fetch_inbox
    @inbox = current_account.inboxes.find(params[:id])
  end

  def check_authorization
    authorize(Inbox)
  end

  def inbox_update_params
    params.require(:inbox).permit(:enable_auto_assignment)
  end
end
