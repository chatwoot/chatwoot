# frozen_string_literal: true

module ActionMailbox
  module Ingresses
    module Resend
      # Controller to handle inbound email webhooks from Resend
      # Receives JSON webhook payload, verifies signature, fetches full email from Resend API,
      # converts to RFC822, and processes via ActionMailbox
      class InboundEmailsController < ActionController::Base
        skip_forgery_protection

        before_action :verify_authenticity

        def create
          # Parse webhook payload
          payload = JSON.parse(request.body.read)

          # Only process email.received events
          return head :ok unless payload['type'] == 'email.received'

          # Extract email_id from webhook
          email_id = payload.dig('data', 'email_id')
          return head(:unprocessable_entity) if email_id.blank?

          # Fetch full email from Resend API
          email_data = fetch_email_from_resend(email_id)
          return head(:internal_server_error) if email_data.nil?

          # Build RFC822 MIME message with full content
          mime_message = build_rfc822_message(email_data)

          # Submit to ActionMailbox for processing
          ActionMailbox::InboundEmail.create_and_extract_message_id!(mime_message)

          head :ok
        rescue JSON::ParserError => e
          Rails.logger.error("Resend webhook: Invalid JSON - #{e.message}")
          head :bad_request
        rescue StandardError => e
          Rails.logger.error("Resend webhook: Processing error - #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          head :internal_server_error
        end

        private

        def verify_authenticity
          # Get raw body for signature verification
          raw_body = request.body.read
          request.body.rewind # Rewind so it can be read again

          # Extract Svix headers
          headers = {
            'svix-id' => request.headers['svix-id'],
            'svix-timestamp' => request.headers['svix-timestamp'],
            'svix-signature' => request.headers['svix-signature']
          }

          unless valid_signature?(raw_body, headers)
            Rails.logger.warn('Resend webhook: Invalid signature')
            head :unauthorized
          end
        end

        def valid_signature?(body, headers)
          return false if headers['svix-signature'].blank?

          secret = ENV.fetch('RESEND_WEBHOOK_SECRET', nil)
          return false if secret.blank?

          # Use Svix to verify webhook signature
          require 'svix'
          wh = Svix::Webhook.new(secret)
          wh.verify(body, headers)
          true
        rescue Svix::WebhookVerificationError => e
          Rails.logger.error("Resend webhook verification failed: #{e.message}")
          false
        rescue StandardError => e
          Rails.logger.error("Resend webhook verification error: #{e.message}")
          false
        end

        def fetch_email_from_resend(email_id)
          api_key = ENV.fetch('RESEND_API_KEY', nil)
          if api_key.blank?
            Rails.logger.error('Resend webhook: RESEND_API_KEY not configured')
            return nil
          end

          uri = URI("https://api.resend.com/emails/receiving/#{email_id}")
          request = Net::HTTP::Get.new(uri)
          request['Authorization'] = "Bearer #{api_key}"
          request['Content-Type'] = 'application/json'

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(request)
          end

          if response.is_a?(Net::HTTPSuccess)
            email_data = JSON.parse(response.body)

            # Log the complete API response structure for research purposes
            Rails.logger.info("=== RESEND API RESPONSE FOR EMAIL #{email_id} ===")
            Rails.logger.info("Response keys: #{email_data.keys.inspect}")
            Rails.logger.info("Full response: #{email_data.inspect}")

            # Specifically check for attachments
            if email_data['attachments'].present?
              Rails.logger.info("ATTACHMENTS FOUND: #{email_data['attachments'].inspect}")
            else
              Rails.logger.info("No attachments field in response")
            end
            Rails.logger.info("=== END RESEND API RESPONSE ===")

            email_data
          else
            Rails.logger.error("Resend API error: #{response.code} - #{response.body}")
            nil
          end
        rescue StandardError => e
          Rails.logger.error("Failed to fetch email from Resend: #{e.message}")
          nil
        end

        def build_rfc822_message(email_data)
          # Use Mail gem to build proper RFC822 MIME message
          require 'mail'

          Mail.new do
            from     email_data['from']
            to       email_data['to']
            cc       email_data['cc'] if email_data['cc'].present?
            bcc      email_data['bcc'] if email_data['bcc'].present?
            subject  email_data['subject'] || '(no subject)'

            # Add threading headers if available
            message_id email_data['message_id'] if email_data['message_id'].present?
            in_reply_to email_data.dig('headers', 'in-reply-to') if email_data.dig('headers', 'in-reply-to').present?
            references email_data.dig('headers', 'references') if email_data.dig('headers', 'references').present?

            # Build multipart message with both text and HTML
            if email_data['html'].present? && email_data['text'].present?
              # Multipart: text + html
              text_part do
                content_type 'text/plain; charset=UTF-8'
                body email_data['text']
              end

              html_part do
                content_type 'text/html; charset=UTF-8'
                body email_data['html']
              end
            elsif email_data['html'].present?
              # HTML only
              content_type 'text/html; charset=UTF-8'
              body email_data['html']
            else
              # Text only
              content_type 'text/plain; charset=UTF-8'
              body email_data['text'] || '(no body)'
            end

            # TODO: Add attachment handling in future enhancement
            # For now, we handle text and HTML emails
          end.to_s
        end
      end
    end
  end
end
