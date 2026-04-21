class Api::V1::Accounts::Synapseos::LeadsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_lead, only: [:show, :update]

  def index
    @leads = scope.order(created_at: :desc).limit(params[:limit].to_i.positive? ? params[:limit].to_i : 100)
  end

  def show; end

  def create
    @lead = scope.new(lead_params)
    @lead.save!
  end

  def update
    @lead.update!(lead_params)
  end

  private

  def scope
    ::Synapseos::Lead.where(account_id: Current.account.id)
  end

  def fetch_lead
    @lead = scope.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(:conversation_id, :contact_id, :assignee_id, :status, :source, metadata: {})
  end

  def check_authorization
    authorize(User, :index?)
  end
end
