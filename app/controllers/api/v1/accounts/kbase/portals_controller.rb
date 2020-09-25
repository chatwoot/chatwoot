class Api::V1::Accounts::Kbase::PortalsController < Api::V1::Accounts::Kbase::BaseController
  before_action :fetch_portal, except: [:index, :create]

  def index
    @portals = Current.account.kbase_portals
  end

  def create
    @portal = Current.account.kbase_portals.create!(portal_params)
  end

  def update
    @portal.update!(portal_params)
  end

  def destroy
    @portal.destroy
    head :ok
  end

  private

  def fetch_portal
    @portal = current_account.kbase_portals.find(params[:id])
  end

  def portal_params
    params.require(:portal).permit(
      :account_id, :color, :custom_domain, :header_text, :homepage_link, :name, :page_title, :slug
    )
  end
end
