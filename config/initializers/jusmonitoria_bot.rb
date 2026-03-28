# frozen_string_literal: true

# JusMonitorIA Bot Auto-Provisioning
# Ensures a global Agent Bot named "JusMonitorIA Bot" exists for async message delivery.
# The bot is created with account_id = NULL (global/system bot) so it can access ANY account.
# Its access_token is cached for use in webhook payloads via Chatwit::JusmonitoriaBot.token
# Also auto-provisions the "jusmonitoria_monitoramento" label in all accounts.

module Chatwit
  module JusmonitoriaBot
    BOT_NAME = 'JusMonitorIA Bot'
    DEFAULT_LABEL = 'jusmonitoria_monitoramento'

    class << self
      def token
        @token ||= fetch_token
      end

      def bot
        @bot ||= find_or_create_bot
      end

      def reset!
        @token = nil
        @bot = nil
      end

      private

      def fetch_token
        bot&.access_token&.token
      end

      def find_or_create_bot
        AgentBot.find_by(name: BOT_NAME, account_id: nil)
      rescue StandardError => e
        Rails.logger.error "[JUSMONITORIA-BOT] Error finding bot: #{e.message}"
        nil
      end
    end
  end
end

Rails.application.config.to_prepare do
  next if Rails.env.test?

  begin
    next unless ActiveRecord::Base.connection.table_exists?('agent_bots')
    next unless ActiveRecord::Base.connection.table_exists?('access_tokens')

    bot = AgentBot.find_by(name: Chatwit::JusmonitoriaBot::BOT_NAME, account_id: nil)

    if bot.nil?
      bot = AgentBot.create!(
        name: Chatwit::JusmonitoriaBot::BOT_NAME,
        description: 'Bot global JusMonitorIA — monitoramento jurídico e encaminhamento de eventos',
        account_id: nil,
        outgoing_url: ''
      )
      Rails.logger.info "[JUSMONITORIA-BOT] Bot global criado — token: #{bot.access_token.token}"
    else
      Rails.logger.info "[JUSMONITORIA-BOT] Bot global já existe (id=#{bot.id}) — token: #{bot.access_token&.token}"
    end

    # Reset cache so it picks up the latest
    Chatwit::JusmonitoriaBot.reset!

    # Auto-provision "jusmonitoria_monitoramento" label in all accounts
    if ActiveRecord::Base.connection.table_exists?('labels')
      Account.find_each do |account|
        label = account.labels.find_by(title: Chatwit::JusmonitoriaBot::DEFAULT_LABEL)
        if label.nil?
          account.labels.create!(
            title: Chatwit::JusmonitoriaBot::DEFAULT_LABEL,
            description: 'JusMonitorIA - Ativa monitoramento de processos jurídicos',
            color: '#6366f1',
            show_on_sidebar: true
          )
          Rails.logger.info "[JUSMONITORIA-BOT] Label '#{Chatwit::JusmonitoriaBot::DEFAULT_LABEL}' criada na account #{account.id}"
        end
      rescue StandardError => e
        Rails.logger.warn "[JUSMONITORIA-BOT] Erro ao criar label na account #{account.id}: #{e.message}"
      end
    end

    # Registrar token no JusMonitorIA
    jusmonitoria_url = ENV.fetch('JUSMONITORIA_WEBHOOK_URL', 'https://api.witdev.com.br')
    chatwit_webhook_secret = ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)
    bot_token = bot.access_token&.token

    if jusmonitoria_url.present? && bot_token.present?
      begin
        response = HTTParty.post(
          "#{jusmonitoria_url}/api/v1/jusmonitoria/integrations/chatwit/init",
          headers: { 'Content-Type' => 'application/json' },
          body: {
            agent_bot_token: bot_token,
            base_url: ENV.fetch('FRONTEND_URL', 'https://chatwit.witdev.com.br'),
            secret: chatwit_webhook_secret
          }.to_json,
          timeout: 10
        )
        Rails.logger.info "[JUSMONITORIA-INIT] Bot token registrado no JusMonitorIA: #{response.code}"
      rescue StandardError => e
        Rails.logger.warn "[JUSMONITORIA-INIT] Falha ao registrar bot token: #{e.message}"
      end
    end
  rescue ActiveRecord::ConnectionNotEstablished
    Rails.logger.info '[JUSMONITORIA-BOT] Skipping — database not available'
  rescue StandardError => e
    Rails.logger.error "[JUSMONITORIA-BOT] Error during auto-provisioning: #{e.message}"
  end
end
