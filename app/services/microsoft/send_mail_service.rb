# Service to send emails via Microsoft Graph API using MIME format
# This bypasses SMTP AUTH requirements and works with Security Defaults enabled
# Using MIME format allows setting In-Reply-To and References headers for proper threading
# Ref: https://learn.microsoft.com/en-us/graph/api/user-sendmail
class Microsoft::SendMailService
  pattr_initialize [:channel!, :message!, :to_emails!, :cc_emails, :bcc_emails, :subject!, :html_body!, :text_body, :in_reply_to, :references]

  GRAPH_API_BASE = 'https://graph.microsoft.com/v1.0'.freeze

  def perform
    response = send_mail_via_graph_api
    handle_response(response)
  end

  private

  def send_mail_via_graph_api
    uri = URI("#{GRAPH_API_BASE}/me/sendMail")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 15
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    request['Content-Type'] = 'text/plain'  # MIME format requires text/plain
    request.body = Base64.strict_encode64(build_mime_message)

    http.request(request)
  end

  def access_token
    # Get a token specifically for Microsoft Graph API
    # The stored token is for outlook.office.com (IMAP), we need one for graph.microsoft.com
    graph_token_service.access_token
  end

  def graph_token_service
    @graph_token_service ||= Microsoft::GraphTokenService.new(channel: channel)
  end

  def build_mime_message
    mail = Mail.new
    apply_mail_headers(mail)
    apply_threading_headers(mail)
    apply_mail_body(mail)
    mail.to_s
  end

  def apply_mail_headers(mail)
    mail.to = Array(to_emails).compact
    mail.from = channel.email
    mail.subject = subject
    mail.message_id = generate_message_id
    mail.cc = Array(cc_emails).compact if cc_emails.present?
    mail.bcc = Array(bcc_emails).compact if bcc_emails.present?
  end

  # Graph API blocks In-Reply-To/References via internetMessageHeaders, but MIME allows them
  def apply_threading_headers(mail)
    return if in_reply_to.blank?

    mail.in_reply_to = ensure_angle_brackets(in_reply_to)
    mail.references = ensure_angle_brackets(references || in_reply_to)
  end

  def apply_mail_body(mail)
    html_content = html_body
    text_content = text_body

    mail.html_part = Mail::Part.new do
      content_type 'text/html; charset=UTF-8'
      body html_content
    end

    return if text_content.blank?

    mail.text_part = Mail::Part.new do
      content_type 'text/plain; charset=UTF-8'
      body text_content
    end
  end

  def ensure_angle_brackets(value)
    return nil if value.blank?

    value = value.to_s.strip
    return value if value.start_with?('<') && value.end_with?('>')

    "<#{value.gsub(/^<|>$/, '')}>"
  end

  def handle_response(response)
    case response.code.to_i
    when 202
      # Success - Microsoft returns 202 Accepted for sendMail
      Rails.logger.info("Microsoft Graph API: Email sent successfully via MIME for message #{message.id}")
      OpenStruct.new(success: true, message_id: generate_message_id)
    when 401
      raise_auth_error('Authentication failed - token may be expired or invalid')
    when 403
      raise_auth_error('Permission denied - Mail.Send scope may be missing')
    else
      error_body = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        { 'error' => { 'message' => response.body } }
      end
      error_message = error_body.dig('error', 'message') || 'Unknown error'
      raise StandardError, "Microsoft Graph API error (#{response.code}): #{error_message}"
    end
  end

  def raise_auth_error(msg)
    Rails.logger.error("Microsoft Graph API: #{msg}")
    raise StandardError, msg
  end

  # Generate a unique message ID that Chatwoot can recognize for threading
  def generate_message_id
    conversation = message.conversation
    "<conversation/#{conversation.uuid}/messages/#{message.id}@#{email_domain}>"
  end

  def email_domain
    channel.email.split('@').last
  end
end
