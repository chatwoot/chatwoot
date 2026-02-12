# frozen_string_literal: true

# SocialWise Bot Auto-Provisioning
# Ensures a global Agent Bot named "Socialwise Bot" exists for async message delivery.
# The bot is created with account_id = NULL (global/system bot) so it can access ANY account.
# Its access_token is cached for use in webhook payloads via Chatwit::SocialwiseBot.token

module Chatwit
  module SocialwiseBot
    BOT_NAME = 'Socialwise Bot'

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
        Rails.logger.error "[SOCIALWISE-BOT] Error finding bot: #{e.message}"
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

    bot = AgentBot.find_by(name: Chatwit::SocialwiseBot::BOT_NAME, account_id: nil)

    if bot.nil?
      bot = AgentBot.create!(
        name: Chatwit::SocialwiseBot::BOT_NAME,
        description: 'Bot global Socialwise — entrega mensagens assíncronas para todas as contas',
        account_id: nil,
        outgoing_url: ''
      )
      Rails.logger.info "[SOCIALWISE-BOT] ✅ Bot global criado — token: #{bot.access_token.token}"
    else
      Rails.logger.info "[SOCIALWISE-BOT] ✅ Bot global já existe (id=#{bot.id}) — token: #{bot.access_token&.token}"
    end

    # Reset cache so it picks up the latest
    Chatwit::SocialwiseBot.reset!
  rescue ActiveRecord::ConnectionNotEstablished
    Rails.logger.info '[SOCIALWISE-BOT] Skipping — database not available'
  rescue StandardError => e
    Rails.logger.error "[SOCIALWISE-BOT] Error during auto-provisioning: #{e.message}"
  end
end
