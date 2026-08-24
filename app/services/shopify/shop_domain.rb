class Shopify::ShopDomain
  FORMAT = /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.myshopify\.com\z/

  def self.normalize(value)
    value.to_s.strip.downcase
  end

  def self.valid?(value)
    normalize(value).match?(FORMAT)
  end
end
