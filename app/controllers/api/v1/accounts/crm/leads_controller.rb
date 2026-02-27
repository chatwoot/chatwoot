class Api::V1::Accounts::Crm::LeadsController < Api::V1::Accounts::BaseController
  before_action :fetch_lead, only: [:show, :update, :destroy]

  def index
    @leads = Current.account.crm_leads.includes(:contact, :user, :crm_stage)
    @leads = @leads.where(crm_stage_id: params[:stage_id]) if params[:stage_id].present?
  end

  def show
  end

  def create
    @lead = Current.account.crm_leads.new(lead_params)
    authorize @lead
    @lead.save!
    render :show
  end

  def update
    authorize @lead
    @lead.update!(lead_params)
    render :show
  end

  def destroy
    authorize @lead
    @lead.destroy!
    head :ok
  end

  private

  def lead_params
    params.require(:crm_lead).permit(:title, :value, :expected_closing_at, :priority, :crm_stage_id, :contact_id, :conversation_id, :user_id)
  end

  def fetch_lead
    @lead = Current.account.crm_leads.find(params[:id])
  end
end
