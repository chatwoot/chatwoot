# Account-specific credentials are encrypted and never returned through account APIs.
class Shopify::CustomApp < ApplicationRecord
  self.table_name = 'shopify_custom_apps'

  belongs_to :account
  encrypts :client_secret
  attr_readonly :account_id, :shop_domain, :client_id

  scope :enabled, -> { where(enabled: true) }

  before_validation { self.shop_domain = Shopify::ShopDomain.normalize(shop_domain) }
  validates :account_id, :shop_domain, :client_id, uniqueness: true
  validates :shop_domain, format: { with: Shopify::ShopDomain::FORMAT }
  validates :client_id, :client_secret, :install_url, presence: true
  validate :validate_install_url
  validate :require_encryption
  validate :preserve_existing_billing

  def connected?
    hook = account.hooks.enabled.find_by(app_id: 'shopify', reference_id: shop_domain)
    hook&.access_token.present? && hook.settings['custom_app_id'] == id
  end

  def callback_path
    "/shopify/accounts/#{account_id}/callback"
  end

  def webhook_path
    "/webhooks/shopify/accounts/#{account_id}"
  end

  def invalidate_authorizations!
    with_lock do
      update!(installation_generation: installation_generation + 1)
    end
  end

  private

  def validate_install_url
    uri = URI.parse(install_url.to_s)
    query = Rack::Utils.parse_query(uri.query)
    expected_url = "https://admin.shopify.com/store/#{shop_domain.to_s.sub(/\.myshopify\.(com|io)\z/, '')}/oauth/install_custom_app"
    uri.query = nil
    valid = uri.to_s == expected_url && query['client_id'] == client_id && query['signature'].present?
    errors.add(:install_url, 'must be the Shopify-generated install link for this app and store') unless valid
  rescue URI::InvalidURIError
    errors.add(:install_url, 'is invalid')
  end

  def require_encryption
    errors.add(:client_secret, 'requires configured Active Record encryption') unless Chatwoot.encryption_configured?
  end

  def preserve_existing_billing
    return unless enabled? && account&.internal_attributes&.fetch('billing_provider', nil) == 'shopify'

    errors.add(:account, 'must use existing non-Shopify billing')
  end
end
