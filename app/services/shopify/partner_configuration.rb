class Shopify::PartnerConfiguration
  DEFAULT_API_VERSION = '2026-07'.freeze
  CORE_KEYS = %w[
    SHOPIFY_PARTNER_ORGANIZATION_ID
    SHOPIFY_PARTNER_APP_ID
    SHOPIFY_PARTNER_ACCESS_TOKEN
  ].freeze
  KEYS = (CORE_KEYS + ['SHOPIFY_PARTNER_API_VERSION']).freeze

  class << self
    def current
      values = {
        'SHOPIFY_PARTNER_ORGANIZATION_ID' => GlobalConfigService.load('SHOPIFY_PARTNER_ORGANIZATION_ID', nil),
        'SHOPIFY_PARTNER_APP_ID' => GlobalConfigService.load('SHOPIFY_PARTNER_APP_ID', nil),
        'SHOPIFY_PARTNER_ACCESS_TOKEN' => GlobalConfigService.load('SHOPIFY_PARTNER_ACCESS_TOKEN', nil),
        'SHOPIFY_PARTNER_API_VERSION' => GlobalConfigService.load('SHOPIFY_PARTNER_API_VERSION', DEFAULT_API_VERSION)
      }
      new(values).validate_complete!
    end

    def validate_for_save!(values)
      new(values).validate_for_save!
    end
  end

  attr_reader :organization_id, :app_id, :access_token, :api_version

  def initialize(values)
    string_values = values.to_h.stringify_keys
    @organization_id = string_values['SHOPIFY_PARTNER_ORGANIZATION_ID'].to_s
    @app_id = string_values['SHOPIFY_PARTNER_APP_ID'].to_s
    @access_token = string_values['SHOPIFY_PARTNER_ACCESS_TOKEN'].to_s
    @api_version = string_values['SHOPIFY_PARTNER_API_VERSION'].presence || DEFAULT_API_VERSION
  end

  def validate_for_save!
    validate_api_version!
    return self if [organization_id, app_id, access_token].all?(&:blank?)

    validate_complete!
  end

  def validate_complete!
    raise Shopify::PartnerClient::ConfigurationError, 'SHOPIFY_PARTNER_ORGANIZATION_ID is required' if organization_id.blank?
    raise Shopify::PartnerClient::ConfigurationError, 'SHOPIFY_PARTNER_APP_ID is required' if app_id.blank?
    raise Shopify::PartnerClient::ConfigurationError, 'SHOPIFY_PARTNER_ACCESS_TOKEN is required' if access_token.blank?
    raise Shopify::PartnerClient::ConfigurationError, 'SHOPIFY_PARTNER_ORGANIZATION_ID must be numeric' unless organization_id.match?(/\A\d+\z/)
    unless app_id.match?(%r{\Agid://shopify/App/\d+\z})
      raise Shopify::PartnerClient::ConfigurationError, 'SHOPIFY_PARTNER_APP_ID must be a Shopify App GID'
    end

    validate_api_version!
    self
  end

  private

  def validate_api_version!
    return if api_version.match?(/\A\d{4}-(0[1-9]|1[0-2])\z/)

    raise Shopify::PartnerClient::ConfigurationError, 'SHOPIFY_PARTNER_API_VERSION must use YYYY-MM format'
  end
end
