# == Schema Information
#
# Table name: channel_apple_messages_for_business
#
#  id                      :bigint           not null, primary key
#  apple_pay_merchant_cert :text
#  auth_sessions           :jsonb
#  imessage_apps           :jsonb
#  imessage_extension_bid  :string           default("com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension")
#  merchant_certificates   :text
#  oauth2_providers        :jsonb
#  payment_processors      :jsonb
#  payment_settings        :jsonb
#  provider_config         :jsonb
#  secret                  :text             not null
#  webhook_url             :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :integer          not null
#  business_id             :string           not null
#  merchant_id             :string
#  msp_id                  :string           not null
#
# Indexes
#
#  index_channel_amb_on_msp_id_and_business_id                      (msp_id,business_id) UNIQUE
#  index_channel_apple_messages_for_business_on_account_id          (account_id)
#  index_channel_apple_messages_for_business_on_business_id         (business_id) UNIQUE
#  index_channel_apple_messages_for_business_on_oauth2_providers    (oauth2_providers) USING gin
#  index_channel_apple_messages_for_business_on_payment_processors  (payment_processors) USING gin
#  index_channel_apple_messages_for_business_on_payment_settings    (payment_settings) USING gin
#
class Channel::AppleMessagesForBusiness < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_apple_messages_for_business'
  EDITABLE_ATTRS = [
    :msp_id, :business_id, :secret, :merchant_id,
    :apple_pay_merchant_cert, :webhook_url, :imessage_extension_bid,
    { provider_config: {} }, { oauth2_providers: {} },
    { payment_settings: {} }, { payment_processors: {} },
    { imessage_apps: [:id, :name, :app_id, :bid, :version, :url, :description, :enabled, :use_live_layout, { app_data: {} }, { images: [] }] }
  ].freeze

  validates :msp_id, presence: true
  validates :business_id, presence: true, uniqueness: true
  validates :secret, presence: true
  validates :msp_id, uniqueness: { scope: :business_id, message: 'combination with business_id already exists' }
  validate :validate_jwt_credentials
  # Temporarily disable strict validations to debug 422 error
  # validate :validate_oauth2_settings
  # validate :validate_payment_settings

  before_save :setup_webhook_url
  after_create :register_webhook

  def name
    'Apple Messages for Business'
  end

  def send_message(destination_id, message)
    AppleMessagesForBusiness::SendMessageService.new(
      channel: self,
      destination_id: destination_id,
      message: message
    ).perform
  end

  def generate_jwt_token
    AppleMessagesForBusiness::JwtService.generate_token(msp_id, secret)
  end

  def verify_jwt_token(token)
    AppleMessagesForBusiness::JwtService.verify_token(token, msp_id, secret)
  end

  def apple_pay_enabled?
    merchant_id.present? && apple_pay_merchant_cert.present? &&
      payment_settings.dig('applePayEnabled') == true
  end

  def oauth2_provider_enabled?(provider)
    oauth2_providers.dig(provider.to_s, 'enabled') == true
  end

  def payment_processor_enabled?(processor)
    payment_processors.dig(processor.to_s, 'enabled') == true
  end

  def configured_oauth2_providers
    return [] unless oauth2_providers.present?

    oauth2_providers.select { |_provider, config| config['enabled'] == true }.keys
  end

  def configured_payment_processors
    return [] unless payment_processors.present?

    payment_processors.select { |_processor, config| config['enabled'] == true }.keys
  end

  def configured_imessage_apps
    return [] unless imessage_apps.present?

    imessage_apps.select { |app| app['enabled'] == true }
  end

  def imessage_app_by_id(app_id)
    return nil unless imessage_apps.present?

    imessage_apps.find { |app| app['id'] == app_id && app['enabled'] == true }
  end

  def has_imessage_apps?
    configured_imessage_apps.any?
  end

  def apple_pay_settings
    return {} unless apple_pay_enabled?

    {
      merchant_identifier: payment_settings['merchantIdentifier'],
      merchant_domain: payment_settings['merchantDomain'],
      supported_networks: payment_settings['supportedNetworks'] || %w[visa masterCard amex],
      merchant_capabilities: payment_settings['merchantCapabilities'] || %w[supports3DS supportsDebit supportsCredit],
      country_code: payment_settings['countryCode'] || 'US',
      currency_code: payment_settings['currencyCode'] || 'USD'
    }
  end

  private

  def validate_jwt_credentials
    return unless msp_id.present? && secret.present?

    begin
      token = generate_jwt_token
      verify_jwt_token(token)
    rescue StandardError => e
      errors.add(:secret, "Invalid JWT credentials: #{e.message}")
    end
  end

  def setup_webhook_url
    return if webhook_url.present?

    base_url = ENV.fetch('FRONTEND_URL', nil).to_s
    base_url = "https://#{base_url}" unless base_url.start_with?('http://', 'https://')
    base_url = base_url.sub(%r{^https?://https?://}, 'https://') # Fix double protocol

    self.webhook_url = "#{base_url}/webhooks/apple_messages_for_business/#{msp_id}/message"
  end

  def register_webhook
    # Apple MSP doesn't require explicit webhook registration
    # Webhook URL is configured in Apple Business Register
    Rails.logger.info "Apple Messages for Business channel created for MSP ID: #{msp_id}"
  end

  def validate_oauth2_settings
    return unless oauth2_providers.present?

    oauth2_providers.each do |provider, config|
      next unless config['enabled'] == true

      errors.add(:oauth2_providers, "#{provider.capitalize} OAuth2 Client ID is required when enabled") if config['clientId'].blank?

      errors.add(:oauth2_providers, "#{provider.capitalize} OAuth2 Client Secret is required when enabled") if config['clientSecret'].blank?
    end
  end

  def validate_payment_settings
    return unless payment_settings.present? && payment_settings['applePayEnabled'] == true

    errors.add(:payment_settings, 'Merchant Identifier is required when Apple Pay is enabled') if payment_settings['merchantIdentifier'].blank?

    errors.add(:payment_settings, 'Merchant Domain is required when Apple Pay is enabled') if payment_settings['merchantDomain'].blank?

    # Validate at least one payment processor is configured
    return unless payment_processors.present?

    enabled_processors = payment_processors.select { |_processor, config| config['enabled'] == true }

    errors.add(:payment_processors, 'At least one payment processor must be enabled when Apple Pay is enabled') if enabled_processors.empty?

    # Validate payment processor credentials
    enabled_processors.each do |processor, config|
      case processor
      when 'stripe'
        validate_stripe_credentials(config)
      when 'square'
        validate_square_credentials(config)
      when 'braintree'
        validate_braintree_credentials(config)
      end
    end
  end

  def validate_stripe_credentials(config)
    errors.add(:payment_processors, 'Stripe Publishable Key is required') if config['publishableKey'].blank?

    return if config['secretKey'].present?

    errors.add(:payment_processors, 'Stripe Secret Key is required')
  end

  def validate_square_credentials(config)
    errors.add(:payment_processors, 'Square Application ID is required') if config['applicationId'].blank?

    return if config['accessToken'].present?

    errors.add(:payment_processors, 'Square Access Token is required')
  end

  def validate_braintree_credentials(config)
    errors.add(:payment_processors, 'Braintree Merchant ID is required') if config['merchantId'].blank?

    errors.add(:payment_processors, 'Braintree Public Key is required') if config['publicKey'].blank?

    return if config['privateKey'].present?

    errors.add(:payment_processors, 'Braintree Private Key is required')
  end
end
