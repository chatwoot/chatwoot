class Api::V1::Accounts::Kbase::PortalsController < Api::V1::Accounts::BaseController
  before_action :fetch_portal, except: [:index, :create]

  def index
    @portals = current_account.kbase_portals
  end

  def create
    @portal = current_account.kbase_portals.create!(portal_params)
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
      :color, :custom_domain, :favicon,
      :footer_title, :footer_url, :header_image,
      :header_text, :homepage_link, :logo,
      :name, :page_title, :social_media_image,
      :subdomain
    )
  end
end
