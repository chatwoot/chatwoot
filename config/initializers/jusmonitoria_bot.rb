# frozen_string_literal: true

# JusMonitorIA Bot Auto-Provisioning
# Ensures a global Agent Bot named "JusMonitorIA Bot" exists for async message delivery.
# The bot is created with account_id = NULL (global/system bot) so it can access ANY account.
# Its access_token is cached for use in webhook payloads via Chatwit::JusmonitoriaBot.token
# Also auto-provisions the "jusmonitoria_monitoramento" label in all accounts.
# rubocop:disable Metrics/ModuleLength

module Chatwit::JusmonitoriaBot
  BOT_NAME = 'JusMonitorIA Bot'
  DEFAULT_LABEL = 'jusmonitoria_monitoramento'
  DEFAULT_PLATFORM_URL = 'https://api.witdev.com.br'
  DEFAULT_FRONTEND_URL = 'https://chatwit.witdev.com.br'
  DEFAULT_LABEL_COLOR = '#6366f1'
  INIT_PATH = '/api/v1/jusmonitoria/integrations/chatwit/init'

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
      ensure_default_labels!
      register_bot_token!(current_bot)
    rescue ActiveRecord::ConnectionNotEstablished
      Rails.logger.info '[JUSMONITORIA-BOT] Skipping — database not available'
    rescue StandardError => e
      Rails.logger.error "[JUSMONITORIA-BOT] Error during auto-provisioning: #{e.message}"
    end

    private

    def fetch_token
      bot&.access_token&.token
    end

    def find_bot
      AgentBot.find_by(name: BOT_NAME, account_id: nil)
    rescue StandardError => e
      Rails.logger.error "[JUSMONITORIA-BOT] Error finding bot: #{e.message}"
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
        description: 'Bot global JusMonitorIA — monitoramento jurídico e encaminhamento de eventos',
        account_id: nil,
        outgoing_url: ''
      )
      Rails.logger.info "[JUSMONITORIA-BOT] Bot global criado — token: #{current_bot.access_token&.token}"
      current_bot
    end

    def log_existing_bot(current_bot)
      Rails.logger.info "[JUSMONITORIA-BOT] Bot global já existe (id=#{current_bot.id}) — token: #{current_bot.access_token&.token}"
      current_bot
    end

    def ensure_default_labels!
      return unless ActiveRecord::Base.connection.table_exists?('labels')

      Account.find_each do |account|
        ensure_default_label_for!(account)
      rescue StandardError => e
        Rails.logger.warn "[JUSMONITORIA-BOT] Erro ao criar label na account #{account.id}: #{e.message}"
      end
    end

    def ensure_default_label_for!(account)
      return if account.labels.find_by(title: DEFAULT_LABEL).present?

      account.labels.create!(
        title: DEFAULT_LABEL,
        description: 'JusMonitorIA - Ativa monitoramento de processos jurídicos',
        color: DEFAULT_LABEL_COLOR,
        show_on_sidebar: true
      )
      Rails.logger.info "[JUSMONITORIA-BOT] Label '#{DEFAULT_LABEL}' criada na account #{account.id}"
    end

    def register_bot_token!(current_bot)
      platform_url = ENV.fetch('JUSMONITORIA_WEBHOOK_URL', DEFAULT_PLATFORM_URL)
      bot_token = current_bot.access_token&.token
      return unless platform_url.present? && bot_token.present?

      response = HTTParty.post(
        "#{platform_url}#{INIT_PATH}",
        headers: { 'Content-Type' => 'application/json' },
        body: init_payload(bot_token).to_json,
        timeout: 10
      )
      Rails.logger.info "[JUSMONITORIA-INIT] Bot token registrado no JusMonitorIA: #{response.code}"
    rescue StandardError => e
      Rails.logger.warn "[JUSMONITORIA-INIT] Falha ao registrar bot token: #{e.message}"
    end

    def init_payload(bot_token)
      {
        agent_bot_token: bot_token,
        base_url: ENV.fetch('FRONTEND_URL', DEFAULT_FRONTEND_URL),
        secret: ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)
      }
    end
  end
end
# rubocop:enable Metrics/ModuleLength

Rails.application.config.to_prepare do
  Chatwit::JusmonitoriaBot.provision!
end
