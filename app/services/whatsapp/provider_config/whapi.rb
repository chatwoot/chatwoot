# frozen_string_literal: true

module Whatsapp
  module ProviderConfig
    class Whapi < Base
      def validate_config?
        # For Whapi partner channels in pending status, we don't require health check
        # since the WhatsApp connection is established after QR code scanning
        if whapi_partner_channel? && whapi_connection_status == 'pending'
          # Validate that we have the required token from partner API
          return api_key.present? || whapi_channel_token.present?
        end

        # For regular Whapi channels or connected partner channels, perform health check
        validate_whapi_health_check
      end

      def api_key
        channel.provider_config&.[]('api_key')
      end

      private

      def validate_whapi_health_check
        response = HTTParty.get("#{api_base_path}/health", headers: api_headers)
        response.success?
      rescue Net::ReadTimeout, Net::OpenTimeout, SocketError => e
        Rails.logger.error "WHAPI health check failed: #{e.message}"
        false
      end

      def api_base_path
        'https://gate.whapi.cloud'
      end

      def api_headers
        { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
      end

      def webhook_verify_token
        # Whapi doesn't use webhook verify tokens
        nil
      end

      def whapi_channel_id
        channel.provider_config&.[]('whapi_channel_id')
      end

      def whapi_channel_token
        channel.provider_config&.[]('whapi_channel_token')
      end

      def whapi_connection_status
        channel.provider_config&.[]('connection_status') || 'pending'
      end

      def whapi_partner_channel?
        whapi_channel_id.present?
      end

      def update_connection_status(status)
        config = channel.provider_config || {}
        config['connection_status'] = status
        config['connected_at'] = Time.current.iso8601 if status == 'connected'
        channel.update!(provider_config: config)
      end

      def update_phone_number(phone_number)
        config = channel.provider_config || {}
        config['phone_number'] = phone_number
        config['phone_synced_at'] = Time.current.iso8601
        channel.update!(provider_config: config, phone_number: phone_number)
      end

      def update_user_status(status)
        config = channel.provider_config || {}
        config['user_status'] = status
        channel.update!(provider_config: config)
      end

      def update_webhook_url(url)
        config = channel.provider_config || {}
        config['webhook_url'] = url
        config['webhook_updated_with_phone'] = true
        config['webhook_updated_at'] = Time.current.iso8601
        channel.update!(provider_config: config)
      end

      def set_webhook_phone_update_error(error_message)
        config = channel.provider_config || {}
        config['webhook_phone_update_error'] = error_message
        channel.update!(provider_config: config)
      end

      def set_webhook_failed(error_message)
        config = channel.provider_config || {}
        config['webhook_status'] = 'failed'
        config['webhook_error'] = error_message
        config['webhook_retry_needed'] = true
        channel.update!(provider_config: config)
      end

      def set_webhook_configured(webhook_url)
        config = channel.provider_config || {}
        config['webhook_status'] = 'configured'
        config['webhook_url'] = webhook_url
        config['webhook_retry_needed'] = false
        config.delete('webhook_error')
        config['webhook_configured_at'] = Time.current.iso8601
        channel.update!(provider_config: config)
      end

      def update_onboarding_data(onboarding_data)
        config = channel.provider_config || {}
        config['onboarding'] = onboarding_data
        channel.update!(provider_config: config)
      end

      def update_qr_timestamp
        config = channel.provider_config || {}
        onboarding = config['onboarding'] || {}
        onboarding['last_qr_at'] = Time.current.iso8601
        config['onboarding'] = onboarding
        channel.update!(provider_config: config)
      end

      def set_webhook_retry_info(error_message)
        config = channel.provider_config || {}
        config['webhook_status'] = 'failed'
        config['webhook_error'] = error_message
        config['webhook_retry_needed'] = true
        config['last_webhook_retry_at'] = Time.current.iso8601
        channel.update!(provider_config: config)
      end

      def cleanup_on_destroy
        return unless whapi_partner_channel?

        Whatsapp::Whapi::WhapiChannelCleanupJob.perform_later(whapi_channel_id)
      rescue StandardError => e
        Rails.logger.warn("Failed to enqueue WhapiChannelCleanupJob for channel ##{channel.id}: #{e.message}")
      end
    end
  end
end