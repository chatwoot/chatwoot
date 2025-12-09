class Api::V1::Accounts::Funnels::FunnelContactsController < Api::V1::Accounts::BaseController
  before_action :fetch_funnel
  before_action :fetch_contact, only: [:update, :destroy]
  before_action :check_authorization

  def index
    @funnel_contacts = @funnel.funnel_contacts
                              .includes(:contact)
                              .order(:column_id, :position)
  end

  def create
    @funnel_contact = @funnel.funnel_contacts.find_or_initialize_by(
      contact_id: params[:contact_id]
    )
    @funnel_contact.column_id = params[:column_id] || @funnel.columns.first&.dig('id')
    @funnel_contact.save!
  end

  def update
    @funnel_contact.update!(funnel_contact_params)
  end

  def destroy
    @funnel_contact.destroy!
    head :ok
  end

  private

  def fetch_funnel
    @funnel = Current.account.funnels.find(params[:funnel_id])
  end

  def fetch_contact
    @funnel_contact = @funnel.funnel_contacts.find_by!(contact_id: params[:contact_id])
  end

  def funnel_contact_params
    params.require(:funnel_contact).permit(:column_id, :position)
  end
end
