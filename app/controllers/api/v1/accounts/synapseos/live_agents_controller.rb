class Api::V1::Accounts::Synapseos::LiveAgentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_user, only: [:conversations]

  def index
    @agents = ::Synapseos::LiveAgentsMetricsService.new(Current.account).call
  end

  def conversations
    @conversations = Current.account.conversations
                            .where(assignee_id: @user.id)
                            .includes(:contact)
                            .order(last_activity_at: :desc)
                            .limit(50)
  end

  private

  def set_user
    @user = Current.account.users.find(params[:id])
  end

  def check_authorization
    authorize(User, :index?)
  end
end
