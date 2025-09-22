# frozen_string_literal: true

module Whatsapp
  module ProviderConfig
    class WhatsappCloud < Base
      def validate_config?
        return false unless api_key.present? && phone_number_id.present? && business_account_id.present?

        # Validate by checking if we can access message templates
        response = HTTParty.get("#{business_account_path}/message_templates?access_token=#{api_key}")
        response.success?
      rescue StandardError => e
        Rails.logger.error "WhatsApp Cloud config validation failed: #{e.message}"
        false
      end

      def api_key
        channel.provider_config&.[]('api_key')
      end

      def phone_number_id
        channel.provider_config&.[]('phone_number_id')
      end

      def business_account_id
        channel.provider_config&.[]('business_account_id')
      end

      def webhook_verify_token
        channel.provider_config['webhook_verify_token'] || generate_webhook_verify_token
      end

      def cleanup_on_destroy
        # WhatsApp Cloud doesn't require cleanup
      end
      private

      def business_account_path
        "#{api_base_path}/v14.0/#{business_account_id}"
      end

      def api_base_path
        ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
      end

      def generate_webhook_verify_token
        token = SecureRandom.hex(16)
        config = channel.provider_config || {}
        config['webhook_verify_token'] = token
        channel.update!(provider_config: config) if channel.persisted?
        token
      end
    end
  end
end