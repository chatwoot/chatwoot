module StorefrontAuth
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_storefront!
    helper_method :current_contact, :storefront_token_param
  end

  private

  def authenticate_storefront!
    token_record = StorefrontToken.active.find_by(
      token: params[:token],
      account_id: params[:account_id]
    )

    if token_record.nil?
      render 'storefront/unauthorized', layout: 'storefront', status: :unauthorized
      return
    end

    token_record.touch_last_used!
    @storefront_token = token_record
    @current_contact = token_record.contact
    @account = token_record.account
  end

  def current_contact
    @current_contact
  end

  def storefront_token_param
    @storefront_token&.token
  end
end
