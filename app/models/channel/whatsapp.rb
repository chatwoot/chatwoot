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
  # CUSTOMIZAÇÃO_SYNAPSEOS: adicionamos Hyperflow (BSP Brasil), Avisa API (não
  # oficial) e d360_cloud (Cloud API hospedada na 360dialog, waba-v2 — o
  # provider 'default' é a API v1 LEGADA da 360dialog, outra coisa).
  PROVIDERS = %w[default whatsapp_cloud hyperflow avisa d360_cloud].freeze
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

  # CUSTOMIZAÇÃO_SYNAPSEOS: replica a credencial no n8n via API agentic. Roda em
  # create e em update quando o segredo (api_key / shared_secret) muda.
  after_commit :enqueue_synapseos_credential_sync, on: %i[create update], if: :should_sync_synapseos_credential?

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
    when 'd360_cloud'
      # CUSTOMIZAÇÃO_SYNAPSEOS
      Whatsapp::Providers::WhatsappD360CloudService.new(whatsapp_channel: self)
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
  delegate :media_download_url, to: :provider_service
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

  SYNAPSEOS_PROVIDERS = %w[avisa whatsapp_cloud hyperflow].freeze
  SYNAPSEOS_SECRET_KEYS = %w[api_key shared_secret phone_number_id business_account_id].freeze

  # On create always sync; on update sync only when a relevant secret key
  # actually changed. This guards the loop where the job itself writes
  # `synapseos_credential_id` back into provider_config (via update_column,
  # which already skips callbacks — belt + suspenders).
  def should_sync_synapseos_credential?
    return false unless SYNAPSEOS_PROVIDERS.include?(provider)
    return true if previously_new_record?
    return false unless saved_change_to_provider_config?

    before, after = saved_change_to_provider_config
    before ||= {}
    after ||= {}
    SYNAPSEOS_SECRET_KEYS.any? { |k| before[k] != after[k] }
  end

  def enqueue_synapseos_credential_sync
    Synapseos::SyncWhatsappCredentialJob.perform_later(id)
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: registra URL de inbound na Avisa API dentro da
  # transação. Falha → rollback → inbox não é criada. Idempotente na Avisa.
  #
  # Em arquiteturas n8n-único (Audi piloto) o webhook Avisa aponta pro
  # bridge n8n, não pro Chatwoot. Se o operador setar
  # provider_config['skip_avisa_webhook_setup'] = true, NÃO mexemos no
  # webhook — qualquer save subsequente preserva a configuração externa.
  def register_avisa_webhook!
    if provider_config['skip_avisa_webhook_setup']
      Rails.logger.info("[AVISA] skip_avisa_webhook_setup=true — não toca no webhook (arquitetura n8n-único)")
      return
    end

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
