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

  before_save :setup_webhooks
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

  private

  def ensure_webhook_verify_token
    provider_config['webhook_verify_token'] ||= SecureRandom.hex(16) if provider == 'whatsapp_cloud'
  end

  def validate_provider_config
    errors.add(:provider_config, 'Invalid Credentials') unless provider_service.validate_provider_config?
  end

  def setup_webhooks
    return unless should_setup_webhooks?

    perform_webhook_setup
  rescue StandardError => e
    handle_webhook_setup_error(e)
  end

  def provider_config_changed?
    will_save_change_to_provider_config?
  end

  def should_setup_webhooks?
    whatsapp_cloud_provider? && embedded_signup_source? && webhook_config_present? && provider_config_changed?
  end

  def whatsapp_cloud_provider?
    provider == 'whatsapp_cloud'
  end

  def embedded_signup_source?
    provider_config['source'] == 'embedded_signup'
  end

  def webhook_config_present?
    provider_config['business_account_id'].present? && provider_config['api_key'].present?
  end

  def perform_webhook_setup
    business_account_id = provider_config['business_account_id']
    api_key = provider_config['api_key']

    Whatsapp::WebhookSetupService.new(self, business_account_id, api_key).perform
  end

  def handle_webhook_setup_error(error)
    Rails.logger.error "[WHATSAPP] Webhook setup failed: #{error.message}"
    # Don't raise the error to prevent channel creation from failing
    # Webhooks can be retried later
  end

  def teardown_webhooks
    Whatsapp::WebhookTeardownService.new(self).perform
  end
end
