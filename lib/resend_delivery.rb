# frozen_string_literal: true

require 'net/http'
require 'json'

# Custom ActionMailer delivery method that sends emails via Resend's HTTPS API
# instead of SMTP. This is necessary when SMTP ports are blocked (like on Railway).
class ResendDelivery
  # ActionMailer delivery method interface
  # @param mail [Mail::Message] The email message to deliver
  def deliver!(mail)
    payload = build_payload(mail)
    response = send_request(payload)

    unless response.is_a?(Net::HTTPSuccess)
      error_message = "HTTP #{response.code}: #{response.body.to_s[0..2048]}" # Truncate to 2KB
      raise ResendDeliveryError.new(error_message, http_status: response.code.to_i, response_body: response.body)
    end
  end

  private

  # Build JSON payload for Resend API
  def build_payload(mail)
    payload = {
      from: determine_from_address(mail),
      to: mail.to || [],
      subject: mail.subject.to_s
    }

    # Add CC and BCC if present
    payload[:cc] = mail.cc if mail.cc.present?
    payload[:bcc] = mail.bcc if mail.bcc.present?

    # Handle body content
    if mail.multipart?
      payload[:html] = mail.html_part&.decoded if mail.html_part
      payload[:text] = mail.text_part&.decoded if mail.text_part
    else
      body = mail.body.decoded.to_s
      if detect_html?(body)
        payload[:html] = body
      else
        payload[:text] = body
      end
    end

    payload
  end

  # Determine sender address
  def determine_from_address(mail)
    ENV['RESEND_FROM'] ||
      ENV['MAILER_SENDER_EMAIL'] ||
      mail.from&.first
  end

  # Detect if content is HTML
  def detect_html?(body)
    return false if body.blank?

    body_str = body.to_s.strip
    html_patterns = [
      /<html/i,
      /<body/i,
      /<div/i,
      /<p>/i,
      /<br/i,
      /<!DOCTYPE/i
    ]

    html_patterns.any? { |pattern| body_str.match?(pattern) }
  end

  # Send HTTP request to Resend API
  def send_request(payload)
    uri = URI('https://api.resend.com/emails')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = (ENV['RESEND_OPEN_TIMEOUT'] || 10).to_i
    http.read_timeout = (ENV['RESEND_READ_TIMEOUT'] || 20).to_i

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{ENV['RESEND_API_KEY']}"
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json

    http.request(request)
  end
end

# Custom exception for Resend delivery errors
class ResendDeliveryError < StandardError
  attr_reader :http_status, :response_body

  def initialize(message, http_status: nil, response_body: nil)
    @http_status = http_status
    @response_body = response_body
    super(message)
  end
end