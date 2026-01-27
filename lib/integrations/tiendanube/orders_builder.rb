class Integrations::Tiendanube::OrdersBuilder
  def initialize(hook:)
    @hook = hook
  end

  def fetch_orders
    response = connection.get('orders') do |req|
      req.params['fields'] =
        'id,number,status,payment_status,total,currency,created_at,contact_email'
    end

    response.body
  end

  private

  def connection
    @connection ||= Faraday.new(
      url: "https://api.tiendanube.com/v1/#{store_id}"
    ) do |f|
      f.request :json
      f.response :json
    end.tap do |conn|
      conn.headers['Authentication'] = "bearer #{@hook.access_token}"
      conn.headers['User-Agent'] = 'Chatwoot (integrations@chatwoot.com)'
      conn.headers['Content-Type'] = 'application/json'
    end
  end

  def store_id
    @hook.reference_id
  end
end
