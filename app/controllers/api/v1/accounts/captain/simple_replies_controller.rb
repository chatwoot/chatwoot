class Api::V1::Accounts::Captain::SimpleRepliesController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(Captain::SimpleReply) }
  before_action :set_assistant
  before_action :set_simple_reply, only: [:show, :update, :destroy]

  def index
    @simple_replies = assistant_simple_replies.enabled
  end

  def show; end

  def create
    @simple_reply = assistant_simple_replies.create!(simple_reply_params.merge(account: Current.account))
  end

  def update
    @simple_reply.update!(simple_reply_params)
  end

  def destroy
    @simple_reply.destroy
    head :no_content
  end

  private

  def set_assistant
    @assistant = account_assistants.find(params[:assistant_id])
  end

  def account_assistants
    @account_assistants ||= Current.account.captain_assistants
  end

  def set_simple_reply
    @simple_reply = assistant_simple_replies.find(params[:id])
  end

  def assistant_simple_replies
    @assistant.simple_replies
  end

  def simple_reply_params
    params.require(:simple_reply).permit(:name, :reply, :match_type, :enabled, keywords: [])
  end
end
