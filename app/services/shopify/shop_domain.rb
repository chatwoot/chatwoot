class Shopify::ShopDomain
  FORMAT = /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.myshopify\.(?:com|io)\z/

  def self.normalize(value)
    value.to_s.strip.downcase
  end

  def self.valid?(value)
    normalize(value).match?(FORMAT)
  end
end
