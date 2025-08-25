require 'base64'

module Whatsapp
  module Partner
    class WhapiPartnerService
      include HTTParty

      base_uri ENV.fetch('WHAPI_PARTNER_BASE_URL', nil)

      # HTTParty timeout configuration for better network handling
      default_timeout 10
      open_timeout 5
      read_timeout 10

      # Circuit breaker configuration
      WHAPI_SERVICE_DOWN_CACHE_KEY = 'whapi_service_down'.freeze
      WHAPI_SERVICE_DOWN_TTL = 300 # 5 minutes

      def initialize(partner_token: ENV.fetch('WHAPI_PARTNER_TOKEN', nil), api_base_url: ENV.fetch('WHAPI_API_BASE_URL', nil))
        @partner_headers = {
          'Authorization' => "Bearer #{partner_token}",
          'Content-Type' => 'application/json'
        }
        @api_base_url = api_base_url
      end

      def fetch_projects
        response = self.class.get('/projects', headers: @partner_headers)
        if response.success?
          parsed = response.parsed_response
          # Spec: GET /projects returns an object with key 'projects'
          # Normalize to always return an Array of project hashes
          projects = parsed.is_a?(Hash) ? (parsed['projects'] || []) : Array(parsed)
          return projects
        end

        raise(StandardError, "WHAPI Partner fetch_projects failed: #{safe_error_message(response)}")
      end

      def create_channel(name:, project_id:)
        payload = {
          name: name,
          projectId: project_id
        }

        # Per docs: PUT /channels on manager.whapi.cloud
        response = self.class.put('/channels', headers: @partner_headers, body: payload.to_json)
        raise(StandardError, "WHAPI Partner create_channel failed: #{safe_error_message(response)}") unless response.success?

        data = response.parsed_response || {}

        # Ensure data is a hash before calling dig
        if data.is_a?(Hash)
          channel_id = data['id'] || data.dig('channel', 'id') || data.dig('data', 'id')
          channel_token = data['token'] || data['api_key'] || data.dig('channel', 'token') || data.dig('data', 'token')
        else
          # If data is not a hash, we can't extract id/token reliably
          channel_id = nil
          channel_token = nil
        end

        raise(StandardError, 'WHAPI Partner create_channel response missing id or token') unless channel_id.present? && channel_token.present?

        { 'id' => channel_id, 'token' => channel_token }
      end

      # Set webhook at channel level using per-channel token against API base
      # Docs: PATCH /settings with Authorization: Bearer <channel token>
      def update_channel_webhook(channel_token:, webhook_url:, retries: 3)
        # Configure webhook with comprehensive settings for message sync
        payload = {
          webhooks: [
            {
              events: [
                {
                  type: 'messages',
                  method: 'post'
                },
                {
                  type: 'statuses',
                  method: 'post'
                }
              ],
              mode: 'body',
              url: webhook_url
            }
          ],
          callback_persist: true,
          media: {
            auto_download: %w[image audio voice video document sticker]
          }
        }

        attempt = 0
        last_error = nil

        while attempt < retries
          attempt += 1

          begin
            response = self.class.patch(
              "#{api_base_url}/settings",
              headers: api_headers_with_channel_token(channel_token),
              body: payload.to_json,
              timeout: 12,
              read_timeout: 10,
              open_timeout: 5
            )

            if response.success?
              Rails.logger.info "[WhapiPartner] Webhook configured successfully on attempt #{attempt}"
              return response.parsed_response
            end

            last_error = "HTTP #{response.code}: #{safe_error_message(response)}"
            Rails.logger.warn "[WhapiPartner] Webhook setup attempt #{attempt} failed: #{last_error}"

          rescue Net::ReadTimeout, Net::OpenTimeout => e
            last_error = "Timeout: #{e.message}"
            Rails.logger.warn "[WhapiPartner] Webhook setup attempt #{attempt} timed out: #{last_error}"
          rescue StandardError => e
            last_error = "Error: #{e.message}"
            Rails.logger.warn "[WhapiPartner] Webhook setup attempt #{attempt} failed: #{last_error}"
          end

          # Linear backoff instead of exponential - faster recovery
          if attempt < retries
            sleep_time = attempt # 1s, 2s, 3s instead of 1s, 2s, 4s
            sleep(sleep_time)
          end
        end

        raise(StandardError, "WHAPI update_channel_webhook failed after #{retries} attempts. Last error: #{last_error}")
      end

      # Authenticates using the per-channel token against WHAPI_API_BASE_URL
      # Canonical endpoint: GET /users/login → returns QR as base64
      def generate_qr_code(channel_token:)
        # Check circuit breaker before attempting
        Rails.logger.warn '[WhapiPartner] Service is degraded, using minimal timeout for QR generation' if service_degraded?

        generate_qr_code_base64_with_retry(channel_token: channel_token)
      end

      def generate_qr_code_base64_with_retry(channel_token:, retries: 3)
        # Check if service is known to be down
        if Rails.cache.read(WHAPI_SERVICE_DOWN_CACHE_KEY)
          raise StandardError, 'WHAPI service is temporarily unavailable. Please try again in a few minutes.'
        end

        last_error = nil

        retries.times do |attempt|
          Rails.logger.info "[WhapiPartner] QR Code base64 attempt #{attempt + 1} of #{retries}"
          result = generate_qr_code_base64(channel_token: channel_token)

          # Clear circuit breaker on success
          Rails.cache.delete(WHAPI_SERVICE_DOWN_CACHE_KEY)
          return result

        rescue StandardError => e
          last_error = e.message

          # Don't retry if channel is already authenticated
          if e.message.include?('already authenticated')
            Rails.logger.info '[WhapiPartner] QR Code: Channel already authenticated, stopping retries'
            raise e
          end

          # Check for service degradation patterns
          mark_service_degraded if e.message.include?('503') || e.message.include?('temporarily unavailable')

          Rails.logger.warn "[WhapiPartner] QR Code base64 attempt #{attempt + 1} failed: #{last_error}"

          # Linear backoff with faster recovery - wait before retry, but not on the last attempt
          if attempt < retries - 1
            sleep_time = [1, 2, 3][attempt] || 3 # 1s, 2s, 3s instead of 1s, 2s, 4s
            Rails.logger.info "[WhapiPartner] QR Code: Waiting #{sleep_time}s before retry..."
            sleep(sleep_time)
          end
        end

        # Mark service as potentially down after all retries fail
        if last_error&.include?('Timeout') || last_error&.include?('503')
          Rails.cache.write(WHAPI_SERVICE_DOWN_CACHE_KEY, true, expires_in: WHAPI_SERVICE_DOWN_TTL)
        end

        raise(StandardError, "WHAPI generate_qr_code_base64 failed after #{retries} attempts. Last error: #{last_error}")
      end

      def delete_channel(channel_id:)
        response = self.class.delete("/channels/#{channel_id}", headers: @partner_headers)
        return true if response.success?

        raise(StandardError, "WHAPI Partner delete_channel failed: #{safe_error_message(response)}")
      end

      # Retry webhook configuration for existing channels
      def retry_webhook_setup(channel_token:, webhook_url:)
        Rails.logger.info '[WhapiPartner] Retrying webhook setup for existing channel'
        update_channel_webhook(channel_token: channel_token, webhook_url: webhook_url, retries: 5)
      rescue StandardError => e
        Rails.logger.error "[WhapiPartner] Webhook retry failed: #{e.message}"
        raise e
      end

      # Check webhook configuration status
      def check_webhook_status(channel_token:)
        response = self.class.get(
          "#{api_base_url}/settings",
          headers: api_headers_with_channel_token(channel_token),
          timeout: 8,
          read_timeout: 8,
          open_timeout: 3
        )

        if response.success?
          settings = response.parsed_response || {}
          {
            configured: settings['webhook_url'].present?,
            webhook_url: settings['webhook_url'],
            events: settings['events']
          }
        else
          { configured: false, error: safe_error_message(response) }
        end
      rescue StandardError => e
        { configured: false, error: e.message }
      end

      # Sync the phone number from WHAPI channel after authentication
      def sync_channel_phone_number(channel_token:)
        response = self.class.get(
          "#{api_base_url}/health?wakeup=true&channel_type=web",
          headers: api_headers_with_channel_token(channel_token),
          timeout: 8,
          read_timeout: 8,
          open_timeout: 3
        )

        if response.success?
          health_data = response.parsed_response || {}
          phone_number = extract_phone_number_from_health(health_data)

          if phone_number.present?
            {
              success: true,
              phone_number: phone_number,
              status: health_data.dig('status', 'text') || 'connected'
            }
          else
            Rails.logger.warn "[WhapiPartner] No phone number found in health data: #{health_data.inspect}"
            { success: false, error: 'Phone number not found in response' }
          end
        else
          error_msg = safe_error_message(response)
          Rails.logger.error "[WhapiPartner] Failed to fetch health info: #{error_msg}"
          { success: false, error: error_msg }
        end
      rescue StandardError => e
        Rails.logger.error "[WhapiPartner] Error syncing phone number: #{e.message}"
        { success: false, error: e.message }
      end

      # Update webhook URL with phone number after authentication
      def update_webhook_with_phone_number(channel_token:, phone_number:)
        webhook_service = Whatsapp::WebhookUrlService.new
        new_webhook_url = webhook_service.generate_webhook_url(phone_number: phone_number)

        Rails.logger.info "[WhapiPartner] Updating webhook URL with phone number: #{new_webhook_url}"
        update_channel_webhook(channel_token: channel_token, webhook_url: new_webhook_url, retries: 3)

        # Return the new webhook URL so it can be persisted to provider_config
        new_webhook_url
      rescue StandardError => e
        Rails.logger.error "[WhapiPartner] Failed to update webhook with phone number: #{e.message}"
        raise e
      end

      private

      def generate_qr_code_base64(channel_token:)
        headers = api_headers_with_channel_token(channel_token).merge(
          'Accept' => 'application/json, text/plain, */*'
        )

        # Optimized timeout settings based on service health
        timeout_config = if service_degraded?
                           { timeout: 15, read_timeout: 12, open_timeout: 8 } # More generous timeouts when degraded
                         else
                           { timeout: 8, read_timeout: 6, open_timeout: 3 }   # Aggressive timeouts when healthy
                         end

        response = self.class.get(
          "#{api_base_url}/users/login",
          headers: headers,
          **timeout_config
        )

        # Enhanced logging for debugging
        Rails.logger.info "[WhapiPartner] QR Code Base64 Response: Status=#{response&.code}, Content-Type=#{response&.headers&.[]('content-type')}"
        Rails.logger.info "[WhapiPartner] QR Code Base64 Response Body (first 200 chars): #{response&.body&.[](0, 200)}"

        # Handle specific HTTP status codes
        if response&.code == 503
          mark_service_degraded
          raise(StandardError, 'WHAPI service temporarily unavailable (503). Please try again in a few moments.')
        elsif response&.code == 409
          raise(StandardError, 'Channel already authenticated - WhatsApp account is connected')
        end

        raise(StandardError, "WHAPI generate_qr_code failed: HTTP #{response&.code || 'unknown'}") unless response&.success?

        content_type = response.headers['content-type'].to_s

        # If an image is returned, convert to base64
        if content_type.include?('image')
          Rails.logger.info '[WhapiPartner] QR Code: Received image response, converting to base64'
          return {
            'image_base64' => Base64.strict_encode64(response.body),
            'expires_in' => 20
          }
        end

        # Handle JSON responses
        begin
          parsed = response.parsed_response
          Rails.logger.info "[WhapiPartner] QR Code: Parsed response class=#{parsed.class}, content=#{parsed.inspect}"
        rescue StandardError => e
          Rails.logger.error "[WhapiPartner] QR Code: Failed to parse JSON response: #{e.message}"
          # Try to extract base64 from raw response if JSON parsing fails
          if response.body.present? && response.body.match?(%r{^[A-Za-z0-9+/=]+$})
            Rails.logger.info '[WhapiPartner] QR Code: Using raw response as base64'
            return {
              'image_base64' => response.body.strip,
              'expires_in' => 20
            }
          end
          parsed = nil
        end

        if parsed.is_a?(Hash)
          # Handle the case where channel is already authenticated
          if parsed.dig('error', 'code') == 409 || parsed['error']&.include?('already authenticated')
            raise(StandardError, 'Channel already authenticated - WhatsApp account is connected')
          end

          # Handle the WAITING status - QR code is not ready yet, but will be available soon
          if parsed['status'] == 'WAITING'
            Rails.logger.info '[WhapiPartner] QR Code: Status is WAITING, will retry base64 endpoint'
            raise(StandardError, 'QR code not ready yet, will retry base64 endpoint')
          end

          raw_b64 = parsed['qr'] || parsed['image'] || parsed['image_base64'] || parsed['base64'] || parsed.dig('data', 'qr')
          expires_in = (parsed['expires_in'] || parsed['expire'] || parsed['ttl'] || 20).to_i

          Rails.logger.info "[WhapiPartner] QR Code: Found base64 in hash, length=#{raw_b64&.length}"

          if raw_b64.present?
            # Clean up data URL prefix if present
            raw_b64 = raw_b64.split(',').last if raw_b64.to_s.start_with?('data:image')
            return {
              'image_base64' => raw_b64,
              'expires_in' => expires_in.positive? ? expires_in : 20
            }
          end
        elsif parsed.is_a?(String) && parsed.present?
          raw_b64 = parsed.to_s.strip
          # Clean up data URL prefix if present
          raw_b64 = raw_b64.split(',').last if raw_b64.start_with?('data:image')

          Rails.logger.info "[WhapiPartner] QR Code: Using string response as base64, length=#{raw_b64.length}"

          return {
            'image_base64' => raw_b64,
            'expires_in' => 20
          }
        end

        # If we can't parse the response, provide detailed error info
        error_details = {
          status: response&.code,
          content_type: content_type,
          body_class: response&.body&.class,
          body_length: response&.body&.length,
          parsed_class: parsed&.class,
          body_preview: response&.body&.[](0, 500) # First 500 chars for debugging
        }

        Rails.logger.error "[WhapiPartner] QR Code: Unexpected response format: #{error_details}"

        # Provide specific error messages based on common scenarios
        if response&.code == 200 && parsed.is_a?(Hash) && parsed['status'] == 'WAITING'
          raise(StandardError, 'QR code not ready yet, will retry base64 endpoint')
        elsif response&.code == 200 && content_type.include?('json') && parsed.nil?
          raise(StandardError, 'WHAPI generate_qr_code failed: invalid JSON response')
        elsif response&.code == 200 && !content_type.include?('json') && !content_type.include?('image')
          raise(StandardError, "WHAPI generate_qr_code failed: unexpected content type #{content_type}")
        else
          raise(StandardError, "WHAPI generate_qr_code failed: unexpected response format. Status: #{response&.code}, Content-Type: #{content_type}")
        end
      end

      # Circuit breaker helper methods
      def service_degraded?
        Rails.cache.read("#{WHAPI_SERVICE_DOWN_CACHE_KEY}_degraded").present?
      end

      def mark_service_degraded
        Rails.cache.write("#{WHAPI_SERVICE_DOWN_CACHE_KEY}_degraded", true, expires_in: 60) # 1 minute
        Rails.logger.warn '[WhapiPartner] Marking service as degraded for 60 seconds'
      end

      def api_headers_with_channel_token(channel_token)
        {
          'Authorization' => "Bearer #{channel_token}",
          'Content-Type' => 'application/json'
        }
      end

      attr_reader :api_base_url

      def safe_error_message(response)
        return 'unknown error' if response.nil? || response.body.nil? || response.body.empty?

        begin
          body = response.parsed_response
        rescue StandardError => e
          Rails.logger.error "[WhapiPartner] Failed to parse response: #{e.message}"
          return response.body.to_s
        end

        return response.body.to_s if body.nil? || body.empty?

        case body
        when Hash
          body['error'] || body['message'] || response.body.to_s
        when String
          body
        else
          response.body.to_s
        end
      end

      def extract_phone_number(user_data)
        return nil unless user_data.is_a?(Hash)

        # Try different possible field names for phone number
        phone_number = user_data['phone'] ||
                       user_data['phone_number'] ||
                       user_data['number'] ||
                       user_data.dig('profile', 'phone') ||
                       user_data.dig('account', 'phone') ||
                       user_data.dig('user', 'phone')

        return nil unless phone_number.present?

        # Ensure phone number is in E.164 format
        formatted_phone = phone_number.to_s.strip
        formatted_phone = "+#{formatted_phone}" unless formatted_phone.start_with?('+')

        Rails.logger.info "[WhapiPartner] Extracted phone number: #{formatted_phone}"
        formatted_phone
      end

      def extract_phone_number_from_health(health_data)
        return nil unless health_data.is_a?(Hash)

        # Extract phone number from health endpoint response
        # The phone number is in user.id field
        phone_number = health_data.dig('user', 'id')

        return nil unless phone_number.present?

        # Ensure phone number is in E.164 format
        formatted_phone = phone_number.to_s.strip
        formatted_phone = "+#{formatted_phone}" unless formatted_phone.start_with?('+')

        Rails.logger.info "[WhapiPartner] Extracted phone number from health: #{formatted_phone}"
        formatted_phone
      end
    end
  end
end