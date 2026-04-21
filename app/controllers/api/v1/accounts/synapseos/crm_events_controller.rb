class Api::V1::Accounts::Synapseos::CrmEventsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    @events = scope.order(created_at: :desc).limit(params[:limit].to_i.positive? ? params[:limit].to_i : 200)
    @events = @events.where(event_type: params[:event_type]) if params[:event_type].present?
    @events = @events.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
  end

  def create
    @event = scope.new(event_params)
    @event.save!
  end

  private

  def scope
    ::Synapseos::CrmEvent.where(account_id: Current.account.id)
  end

  def event_params
    params.require(:crm_event).permit(:conversation_id, :user_id, :event_type, metadata: {})
  end

  def check_authorization
    authorize(User, :index?)
  end
end
