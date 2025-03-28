class Integrations::Shopee::Signature
  pattr_initialize :path, [access_token: nil, shop_id: nil]

  def generate
    extras.merge({
                   timestamp: timestamp,
                   partner_id: partner_id,
                   sign: OpenSSL::HMAC.hexdigest('SHA256', partner_key, base_string)
                 })
  end

  private

  def extras
    {}.tap do |hash|
      hash[:shop_id] = shop_id if shop_id
      hash[:access_token] = access_token if access_token
    end
  end

  def partner_id
    Integrations::Shopee::Constants.partner_id!
  end

  def partner_key
    Integrations::Shopee::Constants.partner_key!
  end

  def timestamp
    @timestamp ||= Time.current.to_i
  end

  # Data: "#{partner_id}#{path}#{timestamp}"
  def base_string
    @base_string ||= [partner_id, path, timestamp, access_token, shop_id].join
  end
end
