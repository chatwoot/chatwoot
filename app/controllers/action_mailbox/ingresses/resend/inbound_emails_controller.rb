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

          # Add email_id to email_data since Resend API doesn't include it in the response
          email_data['email_id'] = email_id

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
            JSON.parse(response.body)
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

          mail = Mail.new
          mail.from = email_data['from']
          mail.to = email_data['to']
          mail.cc = email_data['cc'] if email_data['cc'].present?
          mail.bcc = email_data['bcc'] if email_data['bcc'].present?
          mail.subject = email_data['subject'] || '(no subject)'

          # Add threading headers if available
          mail.message_id = email_data['message_id'] if email_data['message_id'].present?
          mail.in_reply_to = email_data.dig('headers', 'in-reply-to') if email_data.dig('headers', 'in-reply-to').present?
          mail.references = email_data.dig('headers', 'references') if email_data.dig('headers', 'references').present?

          # Determine if we have attachments
          has_attachments = email_data['attachments'].present?

          # Build email body structure
          if email_data['html'].present? && email_data['text'].present?
            # Both text and HTML - create multipart/alternative
            if has_attachments
              # With attachments: multipart/mixed > multipart/alternative > text + html
              mail.text_part = Mail::Part.new do
                content_type 'text/plain; charset=UTF-8'
                body email_data['text']
              end

              mail.html_part = Mail::Part.new do
                content_type 'text/html; charset=UTF-8'
                body email_data['html']
              end
            else
              # Without attachments: just multipart/alternative
              mail.text_part = Mail::Part.new do
                content_type 'text/plain; charset=UTF-8'
                body email_data['text']
              end

              mail.html_part = Mail::Part.new do
                content_type 'text/html; charset=UTF-8'
                body email_data['html']
              end
            end
          elsif email_data['html'].present?
            # HTML only
            mail.content_type = 'text/html; charset=UTF-8'
            mail.body = email_data['html']
          else
            # Text only
            mail.content_type = 'text/plain; charset=UTF-8'
            mail.body = email_data['text'] || '(no body)'
          end

          # Add attachments if present - this will automatically convert to multipart/mixed
          if has_attachments
            email_data['attachments'].each do |attachment_meta|
              add_attachment_to_mail(mail, email_data['email_id'], attachment_meta)
            end
          end

          mail.to_s
        end

        def add_attachment_to_mail(mail, email_id, attachment_meta)
          # Fetch attachment content from Resend API
          attachment_content = fetch_attachment_from_resend(email_id, attachment_meta['id'])
          return if attachment_content.nil?

          # Add attachment to mail
          mail.attachments[attachment_meta['filename']] = {
            content_type: attachment_meta['content_type'],
            content: attachment_content
          }

          # Handle inline attachments (content_id present)
          if attachment_meta['content_id'].present? && attachment_meta['content_disposition'] == 'inline'
            mail.attachments.last.content_id = attachment_meta['content_id']
          end
        rescue StandardError => e
          Rails.logger.error("Failed to add attachment #{attachment_meta['id']}: #{e.message}")
        end

        def fetch_attachment_from_resend(email_id, attachment_id)
          api_key = ENV.fetch('RESEND_API_KEY', nil)
          return nil if api_key.blank?

          # Step 1: Get attachment metadata including download_url
          metadata_uri = URI("https://api.resend.com/emails/receiving/#{email_id}/attachments/#{attachment_id}")
          metadata_request = Net::HTTP::Get.new(metadata_uri)
          metadata_request['Authorization'] = "Bearer #{api_key}"

          metadata_response = Net::HTTP.start(metadata_uri.hostname, metadata_uri.port, use_ssl: true) do |http|
            http.request(metadata_request)
          end

          unless metadata_response.is_a?(Net::HTTPSuccess)
            Rails.logger.error("Resend API error fetching attachment metadata: #{metadata_response.code} - #{metadata_response.body}")
            return nil
          end

          metadata = JSON.parse(metadata_response.body)
          download_url = metadata['download_url']

          if download_url.blank?
            Rails.logger.error("No download_url in attachment metadata")
            return nil
          end

          # Step 2: Download actual file content from the download_url
          download_uri = URI(download_url)
          download_response = Net::HTTP.get_response(download_uri)

          if download_response.is_a?(Net::HTTPSuccess)
            download_response.body
          else
            Rails.logger.error("Failed to download attachment from URL: #{download_response.code}")
            nil
          end
        rescue StandardError => e
          Rails.logger.error("Failed to fetch attachment from Resend: #{e.message}")
          nil
        end
      end
    end
  end
end
