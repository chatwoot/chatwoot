# frozen_string_literal: true

module ActionMailbox
  module Ingresses
    module Resend
      # Controller to handle inbound email webhooks from Resend
      # Receives JSON webhook payload, verifies signature, converts to RFC822, and processes via ActionMailbox
      class InboundEmailsController < ActionController::Base
        skip_forgery_protection

        before_action :verify_authenticity

        def create
          # Parse webhook payload
          payload = JSON.parse(request.body.read)

          # Only process email.received events
          return head :ok unless payload['type'] == 'email.received'

          # Extract email data
          data = payload['data'] || {}
          from = data['from']
          to = (data['to'] || []).join(', ')
          subject = data['subject'] || '(no subject)'
          text = data['text'] || '(no body)'

          # Build RFC822 MIME message (plain text only for MVP)
          mime_message = build_rfc822_message(from: from, to: to, subject: subject, body: text)

          # Submit to ActionMailbox for processing
          ActionMailbox::InboundEmail.create_and_extract_message_id!(mime_message)

          head :ok
        rescue JSON::ParserError => e
          Rails.logger.error("Resend webhook: Invalid JSON - #{e.message}")
          head :bad_request
        rescue StandardError => e
          Rails.logger.error("Resend webhook: Processing error - #{e.message}")
          head :internal_server_error
        end

        private

        def verify_authenticity
          # Get raw body for signature verification
          raw_body = request.body.read
          request.body.rewind # Rewind so it can be read again

          signature = request.headers['Resend-Signature']

          unless valid_signature?(raw_body, signature)
            Rails.logger.warn('Resend webhook: Invalid signature')
            head :unauthorized
          end
        end

        def valid_signature?(body, signature)
          return false if signature.blank?

          secret = ENV.fetch('RESEND_WEBHOOK_SECRET', nil)
          return false if secret.blank?

          # Compute HMAC SHA256 signature
          computed_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, body)

          # Secure comparison to prevent timing attacks
          ActiveSupport::SecurityUtils.secure_compare(computed_signature, signature)
        end

        def build_rfc822_message(from:, to:, subject:, body:)
          # Build simple RFC822 message (plain text only for MVP)
          <<~EMAIL
            From: #{from}
            To: #{to}
            Subject: #{subject}
            Content-Type: text/plain; charset=utf-8

            #{body}
          EMAIL
        end
      end
    end
  end
end
