class Api::V1::InboxesController < Api::BaseController
  before_action :check_authorization
  before_action :fetch_inbox, only: [:destroy]

  def index
    @inboxes = policy_scope(current_account.inboxes)
  end

  def destroy
    @inbox.destroy
    head :ok
  end

  private

  def fetch_inbox
    @inbox = current_account.inboxes.find(params[:id])
  end

  def check_authorization
    authorize(Inbox)
  end
end
