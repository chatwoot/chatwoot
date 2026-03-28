# frozen_string_literal: true

# SocialWise Bot Auto-Provisioning
# Ensures a global Agent Bot named "Socialwise Bot" exists for async message delivery.
# The bot is created with account_id = NULL (global/system bot) so it can access ANY account.
# Its access_token is cached for use in webhook payloads via Chatwit::SocialwiseBot.token

module Chatwit::SocialwiseBot
  BOT_NAME = 'Socialwise Bot'
  DEFAULT_PLATFORM_URL = 'https://api.witdev.com.br'
  DEFAULT_FRONTEND_URL = 'https://chatwit.witdev.com.br'
  INIT_PATH = '/api/integrations/webhooks/socialwiseflow/init'

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
      register_bot_token!(current_bot)
    rescue ActiveRecord::ConnectionNotEstablished
      Rails.logger.info '[SOCIALWISE-BOT] Skipping — database not available'
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-BOT] Error during auto-provisioning: #{e.message}"
    end

    private

    def fetch_token
      bot&.access_token&.token
    end

    def find_bot
      AgentBot.find_by(name: BOT_NAME, account_id: nil)
    rescue StandardError => e
      Rails.logger.error "[SOCIALWISE-BOT] Error finding bot: #{e.message}"
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
        description: 'Bot global Socialwise — entrega mensagens assíncronas para todas as contas',
        account_id: nil,
        outgoing_url: ''
      )
      Rails.logger.info "[SOCIALWISE-BOT] ✅ Bot global criado — token: #{current_bot.access_token&.token}"
      current_bot
    end

    def log_existing_bot(current_bot)
      Rails.logger.info "[SOCIALWISE-BOT] ✅ Bot global já existe (id=#{current_bot.id}) — token: #{current_bot.access_token&.token}"
      current_bot
    end

    def register_bot_token!(current_bot)
      bot_token = current_bot.access_token&.token
      secret = ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)
      platform_url = ENV.fetch('SOCIALWISE_WEBHOOK_URL', DEFAULT_PLATFORM_URL)
      return unless platform_url.present? && secret.present? && bot_token.present?

      response = HTTParty.post(
        "#{platform_url}#{INIT_PATH}",
        headers: { 'Content-Type' => 'application/json' },
        body: init_payload(bot_token, secret).to_json,
        timeout: 10
      )
      Rails.logger.info "[SOCIALWISE-INIT] Bot token registrado no Socialwise: #{response.code}"
    rescue StandardError => e
      Rails.logger.warn "[SOCIALWISE-INIT] Falha ao registrar bot token: #{e.message}"
    end

    def init_payload(bot_token, secret)
      {
        agent_bot_token: bot_token,
        base_url: ENV.fetch('FRONTEND_URL', DEFAULT_FRONTEND_URL),
        secret: secret
      }
    end
  end
end

Rails.application.config.to_prepare do
  Chatwit::SocialwiseBot.provision!
end
