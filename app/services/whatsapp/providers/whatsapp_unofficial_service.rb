# Unofficial WhatsApp provider: bridges Chatwoot to the Baileys companion service
# (see whatsapp-companion/ + PLAN.md). No Meta Business account, no template
# approval — messages are free-form text/media proxied to the companion over HTTP.
#
# Inbound messages arrive via the companion POSTing Cloud-shaped webhooks to
# Webhooks::WhatsappUnofficialController, which reuses the existing
# Whatsapp::IncomingMessageWhatsappCloudService parser. That parser downloads
# media through `media_url` / `api_headers`, so we override those two to point at
# the companion's media endpoint instead of graph.facebook.com.

class Whatsapp::Providers::WhatsappUnofficialService < Whatsapp::Providers::BaseService
  COMPANION_MEDIA_PATH = '/media'.freeze

  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  # Unofficial WhatsApp has no Meta templates. The base `send_template` contract
  # requires this method; we degrade to a free-form text send of the template name
  # (campaigns use `send_message` directly and never hit this path).
  def send_template(phone_number, template_info, _message)
    response = HTTParty.post(
      "#{companion_url}/send",
      headers: companion_headers.merge('Content-Type' => 'application/json'),
      body: {
        identifier: whatsapp_channel.phone_number,
        to: phone_number,
        type: 'text',
        text: template_info[:name].to_s
      }.to_json,
      timeout: 15
    )

    return response.parsed_response['id'] if response.success? && response.parsed_response.is_a?(Hash)

    nil
  end

  # Plain free-form text send — used by campaigns (no templates in unofficial
  # WhatsApp). Returns true on success, false on failure. Kept separate from the
  # Message-based `send_message` so callers that don't have a Message object
  # (campaigns) can send without the error-handling contract.
  def send_free_text(phone_number, text)
    response = HTTParty.post(
      "#{companion_url}/send",
      headers: companion_headers.merge('Content-Type' => 'application/json'),
      body: {
        identifier: whatsapp_channel.phone_number,
        to: phone_number,
        type: 'text',
        text: text
      }.to_json,
      timeout: 15
    )

    response.success?
  rescue StandardError
    false
  end

  def sync_templates
    # Unofficial has no templates endpoint; just stamp last-updated so the sync
    # scheduler stops retrying this channel.
    whatsapp_channel.mark_message_templates_updated
  end

  # Disconnect this number from the companion and clear its persisted Baileys
  # session. Invoked from WebhookTeardownService when an unofficial inbox is
  # deleted, so removing the inbox also stops the WhatsApp socket for that number
  # (otherwise the companion keeps the session connected and listening).
  def logout
    HTTParty.post(
      "#{companion_url}/logout/#{URI.encode_www_form_component(whatsapp_channel.phone_number)}",
      headers: companion_headers,
      timeout: 10
    )
  end

  def error_message(response)
    # Surface companion error body for Message#external_error
    body = response.parsed_response if response.respond_to?(:parsed_response) && response.parsed_response.is_a?(Hash)
    body&.dig('error') || response.body&.truncate(500) || "Companion error #{response.code}"
  rescue StandardError
    response.body&.truncate(500) || 'Companion error'
  end

  def validate_provider_config?
    # Don't block inbox/channel creation if companion is temporarily
    # unreachable — the QR login needs the Channel row to exist first,
    # and transient companion downtime shouldn't make the inbox unsaveable.
    # We still probe the companion when it's reachable so mis-configured
    # URLs surface in logs.
    response = HTTParty.get(
      "#{companion_url}/status/#{URI.encode_www_form_component(whatsapp_channel.phone_number)}",
      headers: companion_headers,
      timeout: 5
    )
    unless response.success?
      Rails.logger.warn("[WHATSAPP_UNOFFICIAL] companion status check non-success (#{response.code}) for #{whatsapp_channel.phone_number} — allowing save")
    end
    true
  rescue StandardError => e
    Rails.logger.warn("[WHATSAPP_UNOFFICIAL] companion status check failed for #{whatsapp_channel.phone_number}: #{e.class} #{e.message} — allowing save")
    true
  end

  # Media download target for the inbound Cloud parser. The companion serves the
  # bytes it cached from WhatsApp; we authenticate with the shared token.
  def media_url(media_id)
    "#{companion_url}#{COMPANION_MEDIA_PATH}/#{URI.encode_www_form_component(whatsapp_channel.phone_number)}/#{media_id}"
  end

  def api_headers
    companion_headers
  end

  # Companion returns { id:, status: } rather than the Cloud { messages: [...] }
  # envelope, so parse it directly and surface failures.
  def process_response(response, message)
    return response.parsed_response['id'] if response.success? && response.parsed_response.is_a?(Hash) && response.parsed_response['id'].present?

    handle_error(response, message)
    nil
  end

  def handle_error(response, message)
    # Companion unreachable (HTTParty raised) -> fabricate a failed status
    if response.nil?
      Rails.logger.error('[WHATSAPP_UNOFFICIAL] companion unreachable (no HTTP response)')
      return if message.blank?

      message.external_error = 'Companion unreachable'
      message.status = :failed
      message.save!
      return
    end

    super
  end

  private

  def companion_url
    Whatsapp::CompanionConfig.companion_url
  end

  def companion_headers
    { 'x-companion-token' => Whatsapp::CompanionConfig.companion_token }
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{companion_url}/send",
      headers: companion_headers.merge('Content-Type' => 'application/json'),
      body: {
        identifier: whatsapp_channel.phone_number,
        to: phone_number,
        type: 'text',
        text: message.outgoing_content
      }.to_json,
      timeout: 15
    )

    process_response(response, message)
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP_UNOFFICIAL] send text failed for #{whatsapp_channel.phone_number}: #{e.class} #{e.message}")
    handle_error(nil, message)
    nil
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    response = HTTParty.post(
      "#{companion_url}/send",
      headers: companion_headers.merge('Content-Type' => 'application/json'),
      body: {
        identifier: whatsapp_channel.phone_number,
        to: phone_number,
        type: type,
        mediaUrl: attachment.download_url,
        caption: message.outgoing_content.presence,
        filename: attachment.file.filename.to_s
      }.to_json,
      timeout: 30
    )

    process_response(response, message)
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP_UNOFFICIAL] send attachment failed for #{whatsapp_channel.phone_number}: #{e.class} #{e.message}")
    handle_error(nil, message)
    nil
  end
end
