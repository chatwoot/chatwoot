class Api::V1::Accounts::Synapseos::DealsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_deal, only: [:show, :update]

  def index
    @deals = scope.order(created_at: :desc).limit(params[:limit].to_i.positive? ? params[:limit].to_i : 100)
  end

  def show; end

  def create
    @deal = scope.new(deal_params)
    stamp_closed_at(@deal)
    @deal.save!
  end

  def update
    @deal.assign_attributes(deal_params)
    stamp_closed_at(@deal) if @deal.status_changed?
    @deal.save!
  end

  def stamp_closed_at(deal)
    deal.closed_at ||= Time.current if deal.status.present? && deal.status != 'pending'
  end

  private

  def scope
    ::Synapseos::Deal.where(account_id: Current.account.id)
  end

  def fetch_deal
    @deal = scope.find(params[:id])
  end

  def deal_params
    params.require(:deal).permit(:lead_id, :assignee_id, :status, :amount, :currency, :closed_at, metadata: {})
  end

  def check_authorization
    authorize(User, :index?)
  end
end
