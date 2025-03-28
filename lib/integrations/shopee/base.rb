class Integrations::Shopee::Base
  pattr_initialize [:shop_id, :access_token]

  private

  def client
    @client ||= Integrations::Shopee::Client.new
  end

  def auth_client
    @auth_client ||= Integrations::Shopee::Client.new(access_token: access_token, shop_id: shop_id)
  end

  def partner_id
    @partner_id ||= Integrations::Shopee::Constants.partner_id!.to_i
  end

  def shop_id
    @shop_id.to_i
  end

  def access_token
    @access_token.presence || raise(ArgumentError, 'Shopee access_token is required')
  end
end
