class Integrations::Shopee::Auth < Integrations::Shopee::Base
  def get_access_token(code)
    client.body({
                  shop_id: shop_id,
                  partner_id: partner_id,
                  code: code
                }).post('/api/v2/auth/token/get')
  end

  def refresh_access_token(token)
    client.body({
                  shop_id: shop_id,
                  partner_id: partner_id,
                  refresh_token: token
                }).post('/api/v2/auth/access_token/get')
  end
end
