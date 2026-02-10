class Api::V1::Accounts::StorefrontLinksController < Api::V1::Accounts::BaseController
  before_action :check_catalog_enabled

  # POST /api/v1/accounts/:account_id/storefront_links
  def create
    contact = Current.account.contacts.find(params[:contact_id])
    token = StorefrontToken.create!(
      account: Current.account,
      contact: contact,
      conversation_id: params[:conversation_id]
    )

    render json: {
      storefront_url: storefront_products_url(Current.account, token: token.token),
      token: token.token,
      expires_at: token.expires_at
    }
  end

  private

  def check_catalog_enabled
    return if Current.account.catalog_settings&.enabled?

    render json: { error: 'Catalog is not enabled' }, status: :unprocessable_entity
  end
end
