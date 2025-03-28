class Integrations::Shopee::Shop < Integrations::Shopee::Base
  def info
    @info ||= auth_client.get('/api/v2/shop/get_shop_info')
  end
end
