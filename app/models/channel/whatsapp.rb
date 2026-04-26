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
  # CUSTOMIZAÇÃO_SYNAPSEOS: adicionamos Hyperflow (BSP Brasil) e Avisa API (não oficial).
  PROVIDERS = %w[default whatsapp_cloud hyperflow avisa].freeze
  before_validation :ensure_webhook_verify_token

  validates :provider, inclusion: { in: PROVIDERS }
  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config

  after_create :sync_templates
  after_create :register_avisa_webhook!, if: -> { provider == 'avisa' }
  after_update :register_avisa_webhook!, if: -> { provider == 'avisa' && saved_change_to_provider_config? }
  before_destroy :teardown_webhooks
  after_commit :setup_webhooks, on: :create, if: :should_auto_setup_webhooks?
  # CUSTOMIZAÇÃO_SYNAPSEOS: Avisa expõe POST /webhook — auto-registramos síncrono
  # dentro da transação; se a Avisa rejeitar (token inválido, offline) a inbox
  # não nasce quebrada. Re-registra em update quando credenciais mudam.
  validate :validate_avisa_frontend_url, if: -> { provider == 'avisa' }

  def name
    'Whatsapp'
  end

  def provider_service
    case provider
    when 'whatsapp_cloud'
      Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: self)
    when 'hyperflow'
      # CUSTOMIZAÇÃO_SYNAPSEOS
      Whatsapp::Providers::HyperflowService.new(whatsapp_channel: self)
    when 'avisa'
      # CUSTOMIZAÇÃO_SYNAPSEOS
      Whatsapp::Providers::AvisaService.new(whatsapp_channel: self)
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

  def setup_webhooks
    perform_webhook_setup
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Webhook setup failed: #{e.message}"
    prompt_reauthorization!
  end

  private

  def ensure_webhook_verify_token
    provider_config['webhook_verify_token'] ||= SecureRandom.hex(16) if provider == 'whatsapp_cloud'
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

  def should_auto_setup_webhooks?
    # Only auto-setup webhooks for whatsapp_cloud provider with manual setup
    # Embedded signup calls setup_webhooks explicitly in EmbeddedSignupService
    provider == 'whatsapp_cloud' && provider_config['source'] != 'embedded_signup'
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: validação upfront — sem FRONTEND_URL não faz sentido
  # criar inbox Avisa (nem teria como informar à Avisa onde mandar os webhooks).
  def validate_avisa_frontend_url
    return if ENV['FRONTEND_URL'].to_s.strip.present?

    errors.add(:base, 'FRONTEND_URL não configurado no servidor — impossível registrar webhook da Avisa.')
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: registra URL de inbound na Avisa API dentro da
  # transação. Falha → rollback → inbox não é criada. Idempotente na Avisa.
  def register_avisa_webhook!
    webhook_url = "#{ENV['FRONTEND_URL'].to_s.chomp('/')}/webhooks/avisa"

    Whatsapp::Providers::AvisaClient.new(
      api_key: provider_config['api_key'],
      base_url: provider_config['base_url']
    ).register_webhook(webhook_url: webhook_url)

    Rails.logger.info("[AVISA] webhook registrado: #{webhook_url}")
  rescue Whatsapp::Providers::AvisaClient::Error => e
    Rails.logger.error("[AVISA] falha ao registrar webhook: #{e.message}")
    errors.add(:base, "Falha ao registrar webhook na Avisa: #{e.message}")
    raise ActiveRecord::RecordInvalid, self
  end
end
