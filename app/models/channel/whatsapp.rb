# == Schema Information
#
# Table name: channel_whatsapp
#
#  id                             :bigint           not null, primary key
#  message_templates              :jsonb
#  message_templates_last_updated :datetime
#  phone_number                   :string           not null
#  provider                       :string           default("default")
#  provider_config                :jsonb
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  account_id                     :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_on_phone_number  (phone_number) UNIQUE
#

class Channel::Whatsapp < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_whatsapp'
  EDITABLE_ATTRS = [:phone_number, :provider, { provider_config: {} }].freeze

  # default at the moment is 360dialog lets change later.
  PROVIDERS = %w[default whatsapp_cloud].freeze
  before_validation :ensure_webhook_verify_token

  validates :provider, inclusion: { in: PROVIDERS }
  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config

  after_create :sync_templates
  before_destroy :teardown_webhooks

  def name
    'Whatsapp'
  end

  def provider_service
    if provider == 'whatsapp_cloud'
      Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: self)
    else
      Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: self)
    end
  end

  def mark_message_templates_updated
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:message_templates_last_updated, Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  delegate :send_message, to: :provider_service
  delegate :send_template, to: :provider_service
  delegate :sync_templates, to: :provider_service
  delegate :media_url, to: :provider_service
  delegate :api_headers, to: :provider_service

  def self.find_by_phone_number_id(phone_number_id)
    where("provider_config->>'phone_number_id' = ?", phone_number_id).first
  end

  def setup_webhooks
    perform_webhook_setup
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Webhook setup failed: #{e.message}"
    # Only prompt reauthorization if it's an actual auth error
    # Don't prompt for network issues, API downtime, or incomplete registration
    prompt_reauthorization! if auth_error?(e)
  end

  private

  def ensure_webhook_verify_token
    return unless provider == 'whatsapp_cloud'
    return if provider_config['webhook_verify_token'].present?

    # Priority order:
    # 1. Account-specific verify token (from whatsapp_settings)
    # 2. Global FB_VERIFY_TOKEN environment variable
    # 3. Generate random token
    account_token = inbox&.account&.whatsapp_settings&.verify_token
    global_token = ENV.fetch('FB_VERIFY_TOKEN', nil)

    provider_config['webhook_verify_token'] = account_token.presence || global_token.presence || SecureRandom.hex(16)
  end

  def validate_provider_config
    errors.add(:provider_config, 'Invalid Credentials') unless provider_service.validate_provider_config?
  end

  def perform_webhook_setup
    business_account_id = provider_config['business_account_id']
    api_key = provider_config['api_key']

    Whatsapp::WebhookSetupService.new(self, business_account_id, api_key).perform
  end

  def teardown_webhooks
    Whatsapp::WebhookTeardownService.new(self).perform
  end

  def auth_error?(error)
    # Check if the error is an authentication/authorization error
    error_message = error.message.to_s.downcase

    # Common auth error patterns from Facebook/WhatsApp API
    auth_patterns = [
      'invalid oauth access token',
      'oauth',
      'access token',
      'expired',
      'unauthorized',
      '401',
      '403',
      'permission',
      'invalid credentials'
    ]

    auth_patterns.any? { |pattern| error_message.include?(pattern) }
  end
end
