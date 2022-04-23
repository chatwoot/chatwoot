class Api::V1::Accounts::Kbase::BaseController < Api::V1::Accounts::BaseController
  before_action :portal

  private

  def portal
    @portal ||= Current.account.kbase_portals.find_by(slug: params[:portal_id])
  end
end
