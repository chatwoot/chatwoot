class Api::V1::Accounts::FunnelsController < Api::V1::Accounts::BaseController
  before_action :fetch_funnel, only: [:show, :update, :destroy, :move_contact]
  before_action :check_authorization

  def index
    if Current.account.funnels.empty?
      Current.account.funnels.create!(
        name: 'geral',
        is_default: true,
        columns: Funnel::DEFAULT_COLUMNS
      )
    end
    @funnels = Current.account.funnels.order(:position, :created_at)
  end

  def show; end

  def create
    @funnel = Current.account.funnels.new(funnel_params)
    @funnel.is_default = true if Current.account.funnels.where(is_default: true).empty?
    @funnel.save!
  end

  def update
    @funnel.update!(funnel_params)
  end

  def destroy
    @funnel.destroy!
    head :ok
  end

  def move_contact
    @funnel_contact = @funnel.funnel_contacts.find_or_initialize_by(
      contact_id: params[:contact_id]
    )
    @funnel_contact.column_id = params[:column_id]
    @funnel_contact.position = params[:position] || 0
    @funnel_contact.save!
    render 'api/v1/accounts/funnels/funnel_contacts/show'
  end

  private

  def fetch_funnel
    @funnel = Current.account.funnels.find(params[:id])
  end

  def funnel_params
    params.require(:funnel).permit(:name, :team_id, columns: [:id, :name, :position])
  end
end
