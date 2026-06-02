# frozen_string_literal: true

# Chatwit Platform Bot — Unified Auto-Provisioning
#
# Single global Agent Bot (account_id = NULL) shared by ALL platform products
# (Socialwise, JusMonitorIA, etc.). Registers once at startup via the unified
# init endpoint on the Witdev Platform FastAPI backend.
#
# Token access: Chatwit::PlatformBot.token
#
# Init endpoint: POST /api/integrations/webhooks/socialwiseflow/init
# Payload: { agent_bot_token, base_url, secret }
# The platform stores the token in SystemConfig — both Socialwise and
# JusMonitorIA read from the same SystemConfig entry.

module Chatwit; end

module Chatwit::PlatformBot
  BOT_NAME = 'Chatwit Platform Bot'
  DEFAULT_PLATFORM_URL = 'https://api.witdev.com.br'
  DEFAULT_FRONTEND_URL = 'https://chatwit.witdev.com.br'
  INIT_PATH = '/api/integrations/webhooks/socialwiseflow/init'

  # JusMonitorIA label provisioning
  JUSMONITORIA_LABEL = 'jusmonitoria_monitoramento'
  JUSMONITORIA_LABEL_COLOR = '#6366f1'

  class << self
    def token
      @token ||= fetch_token
    end

    def bot
      @bot ||= find_bot
    end

    def reset!
      @token = nil
      @bot = nil
    end

    def provision!
      return if Rails.env.test?
      return unless required_tables_available?

      current_bot = ensure_bot!
      reset!
      migrate_legacy_bots!
      ensure_jusmonitoria_labels!
      register_bot_token!(current_bot)
    rescue ActiveRecord::ConnectionNotEstablished
      Rails.logger.info '[PLATFORM-BOT] Skipping — database not available'
    rescue StandardError => e
      Rails.logger.error "[PLATFORM-BOT] Error during auto-provisioning: #{e.message}"
    end

    private

    def fetch_token
      bot&.access_token&.token
    end

    def find_bot
      AgentBot.find_by(name: BOT_NAME, account_id: nil)
    rescue StandardError => e
      Rails.logger.error "[PLATFORM-BOT] Error finding bot: #{e.message}"
      nil
    end

    def required_tables_available?
      ActiveRecord::Base.connection.table_exists?('agent_bots') &&
        ActiveRecord::Base.connection.table_exists?('access_tokens')
    end

    def ensure_bot!
      current_bot = find_bot
      return log_existing_bot(current_bot) if current_bot.present?

      create_bot!
    end

    def create_bot!
      current_bot = AgentBot.create!(
        name: BOT_NAME,
        description: 'Bot global Chatwit Platform — entrega async para Socialwise e JusMonitorIA',
        account_id: nil,
        outgoing_url: ''
      )
      Rails.logger.info "[PLATFORM-BOT] Bot global criado — token: #{current_bot.access_token&.token}"
      current_bot
    end

    def log_existing_bot(current_bot)
      Rails.logger.info "[PLATFORM-BOT] Bot global existe (id=#{current_bot.id})"
      current_bot
    end

    # Migrate legacy separate bots to the unified bot.
    # Removes old "Socialwise Bot" and "JusMonitorIA Bot" if they exist,
    # so there's only one global bot going forward.
    def migrate_legacy_bots!
      ['Socialwise Bot', 'JusMonitorIA Bot'].each do |legacy_name|
        legacy = AgentBot.find_by(name: legacy_name, account_id: nil)
        next unless legacy

        legacy.destroy!
        Rails.logger.info "[PLATFORM-BOT] Legacy bot '#{legacy_name}' removido"
      end
    end

    def ensure_jusmonitoria_labels!
      return unless ActiveRecord::Base.connection.table_exists?('labels')

      Account.find_each do |account|
        next if account.labels.exists?(title: JUSMONITORIA_LABEL)

        account.labels.create!(
          title: JUSMONITORIA_LABEL,
          description: 'JusMonitorIA - Ativa monitoramento de processos jurídicos',
          color: JUSMONITORIA_LABEL_COLOR,
          show_on_sidebar: true
        )
        Rails.logger.info "[PLATFORM-BOT] Label '#{JUSMONITORIA_LABEL}' criada na account #{account.id}"
      rescue StandardError => e
        Rails.logger.warn "[PLATFORM-BOT] Erro ao criar label na account #{account.id}: #{e.message}"
      end
    end

    def register_bot_token!(current_bot)
      bot_token = current_bot.access_token&.token
      secret = ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)
      platform_url = ENV.fetch('SOCIALWISE_WEBHOOK_URL', DEFAULT_PLATFORM_URL)
      return unless platform_url.present? && secret.present? && bot_token.present?

      response = HTTParty.post(
        "#{platform_url}#{INIT_PATH}",
        headers: {
          'Content-Type' => 'application/json',
          'x-webhook-secret' => secret
        },
        body: {
          agent_bot_token: bot_token,
          base_url: ENV.fetch('FRONTEND_URL', DEFAULT_FRONTEND_URL),
          secret: secret
        }.to_json,
        timeout: 10
      )
      Rails.logger.info "[PLATFORM-INIT] Bot token registrado na plataforma: #{response.code}"
    rescue StandardError => e
      Rails.logger.warn "[PLATFORM-INIT] Falha ao registrar bot token: #{e.message}"
    end
  end
end

# Enterprise plan pinning — Chatwit é self-hosted enterprise white-label.
#
# O gating (`ChatwootApp.self_hosted_enterprise?` e `ChatwootHub.pricing_plan`)
# lê INSTALLATION_PRICING_PLAN do InstallationConfig (banco). O ENV de mesmo
# nome no Dockerfile.enterprise NÃO tem efeito — nenhum desses caminhos lê ENV.
# Quem gravava 'enterprise' no banco era o entrypoint
# docker/entrypoints/rails-enterprise.sh, que só roda no compose de produção;
# o dev (docker-compose.yaml) usa rails.sh e cai no default 'community' do seed.
#
# Além disso, o upstream v4.13.0 trouxe Internal::ReconcilePlanConfigService
# (rodado diariamente pelo CheckNewVersionsJob) que, com plano 'community',
# DESABILITA as features premium em todas as contas. Fixar o plano em
# 'enterprise' no boot resolve os dois casos: destrava as features e faz o
# reconcile retornar cedo (no-op). Telemetria fica OFF, então o plano nunca é
# sobrescrito pelo hub.
module Chatwit::EnterprisePlan
  PREMIUM_FEATURES = %w[disable_branding audit_logs sla captain_integration custom_roles response_bot].freeze

  class << self
    def ensure!
      return if Rails.env.test?
      return unless table_available?

      enable_premium_features! if pin_plan!
    rescue ActiveRecord::ConnectionNotEstablished
      Rails.logger.info '[CHATWIT-PLAN] Skipping — database not available'
    rescue StandardError => e
      Rails.logger.error "[CHATWIT-PLAN] Error pinning enterprise plan: #{e.message}"
    end

    private

    def table_available?
      ActiveRecord::Base.connection.table_exists?('installation_configs')
    end

    # Returns true if the pricing plan was (re)set to enterprise this run.
    def pin_plan!
      flipped = upsert_config('INSTALLATION_PRICING_PLAN', 'enterprise')
      upsert_config('INSTALLATION_PRICING_PLAN_QUANTITY', '100')
      GlobalConfig.clear_cache if flipped
      flipped
    end

    def upsert_config(name, value)
      config = InstallationConfig.find_or_initialize_by(name: name)
      return false if config.value.to_s == value.to_s

      config.value = value
      config.save!
      true
    end

    def enable_premium_features!
      return unless ActiveRecord::Base.connection.column_exists?(:accounts, :settings)

      Account.find_each { |account| account.enable_features!(*PREMIUM_FEATURES) }
    end
  end
end

Rails.application.config.to_prepare do
  Chatwit::PlatformBot.provision!
  Chatwit::EnterprisePlan.ensure!
end
