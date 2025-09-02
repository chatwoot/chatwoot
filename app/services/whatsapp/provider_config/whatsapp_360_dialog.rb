# frozen_string_literal: true

module Whatsapp
  module ProviderConfig
    class Whatsapp360Dialog < Base
      def validate_config?
        return false unless api_key.present?

        # Validate by setting up webhook configuration
        response = HTTParty.post(
          "#{api_base_path}/configs/webhook",
          headers: { 'D360-API-KEY': api_key, 'Content-Type': 'application/json' },
          body: {
            url: "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{channel.phone_number}"
          }.to_json
        )
        response.success?
      rescue StandardError => e
        Rails.logger.error "360Dialog config validation failed: #{e.message}"
        false
      end

      def api_key
        channel.provider_config&.[]('api_key')
      end

      def webhook_verify_token
        # 360Dialog doesn't use webhook verify tokens
        nil
      end

      def cleanup_on_destroy
        # 360Dialog doesn't require cleanup
      end

      private

      def api_base_path
        ENV.fetch('360DIALOG_BASE_URL', 'https://waba.360dialog.io/v1')
      end
    end
  end
end