class Whatsapp::Providers::WhatsappCloudService < Whatsapp::Providers::BaseService # rubocop:disable Metrics/ClassLength
  include Whatsapp::GraphRequestOptions
  include Whatsapp::TransportFailure
  include Whatsapp::CredentialCheck

  # The types WhatsApp accepts for a voice message, taken from its own rejection message:
  # "Please use one of audio/ogg; codecs=opus, audio/mpeg, audio/amr, audio/mp4, audio/aac."
  # Measured live in #520: a phone renders every one of them as a voice bubble, and only opus
  # carries a waveform. Requiring opus turned a voice note into a file to tap and protected
  # against nothing, since the API never rejected the others. `audio/amr` is here on WhatsApp's
  # own authority and was not measured, for lack of an AMR encoder to test with; the risk of
  # keeping it is a send that fails, not a wrong bubble.
  #
  # This list is WhatsApp Cloud's. Baileys and the session provider send their own voice flag
  # without looking at the type at all, so hoisting this anywhere shared would break voice notes
  # that work there today.
  VOICE_MESSAGE_CONTENT_TYPES = %w[audio/ogg audio/mpeg audio/amr audio/mp4 audio/aac].freeze

  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    elsif message.content_attributes[:is_reaction]
      send_reaction_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info, message)
    template_body = template_body_parameters(template_info)

    request_body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual', # Only individual messages supported (not group messages)
      # BSUID -> `recipient`; phone number -> `to` (see recipient_params in the base provider).
      **recipient_params(phone_number),
      type: 'template',
      template: template_body
    }

    response = post_outgoing(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: request_body.to_json
    )

    process_response(response, message)
  end

  def sync_templates
    # ensuring that channels with wrong provider config wouldn't keep trying to sync templates
    whatsapp_channel.mark_message_templates_updated
    return if (templates = fetch_whatsapp_templates).blank?

    # update_columns skips touch, so bump the cache key ourselves; only if templates changed
    whatsapp_channel.account.update_cache_key('inbox') if templates != whatsapp_channel.message_templates
    # rubocop:disable Rails/SkipsModelValidations
    whatsapp_channel.update_columns(message_templates: templates, message_templates_last_updated: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def fetch_whatsapp_templates(after: nil)
    options = { headers: { 'Authorization' => "Bearer #{whatsapp_channel.template_access_token}" } }
    options[:query] = { after: after } if after.present?
    response = HTTParty.get("#{business_account_path}/message_templates", **options, **GRAPH_REQUEST_OPTIONS)
    unless response.success?
      Rails.logger.warn "[WHATSAPP] Template sync failed for account #{whatsapp_channel.account_id} " \
                        "inbox #{whatsapp_channel.inbox&.id}: #{response.code} #{error_message(response)}"
      return []
    end

    next_cursor = response.dig('paging', 'cursors', 'after')

    return response['data'] + fetch_whatsapp_templates(after: next_cursor) if next_cursor.present?

    response['data']
  end

  def validate_provider_config?
    config = whatsapp_channel.provider_config
    url = "#{business_account_path}/message_templates?access_token=#{config['api_key']}"
    response = credential_check_request { HTTParty.get(url, **GRAPH_REQUEST_OPTIONS) }
    ensure_credential_verdict!(response)
    return log_transfer_failure('waba_or_token_check', response) unless response.success?
    # The templates check only proves the WABA/token pair, so verify the phone_number_id belongs to this WABA when it changes.
    return true unless whatsapp_channel.provider_config_changed?

    phone_number_belongs_to_waba?(config) && app_secret_matches_token?(config)
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end

  def create_csat_template(template_config)
    csat_template_service.create_template(template_config)
  end

  def delete_csat_template(template_name = nil)
    template_name ||= CsatTemplateNameService.csat_template_name(whatsapp_channel.inbox.id)
    csat_template_service.delete_template(template_name)
  end

  def get_template_status(template_name)
    csat_template_service.get_template_status(template_name)
  end

  def media_url(media_id)
    "#{api_base_path}/v13.0/#{media_id}"
  end

  # Uploads a file to the WhatsApp media store and returns its id, which can then be used in place of a
  # `link` anywhere the API takes media. Meta keeps the upload for 30 days.
  # https://developers.facebook.com/docs/whatsapp/cloud-api/reference/media#upload-media
  #
  # This is the one call that does not go through HTTParty: its multipart bodies are streamed with
  # chunked encoding, and the Graph API answers "(#100) The parameter file is required" to those.
  # Net::HTTP sends a Content-Length, which is what the endpoint expects.
  def upload_media(file, content_type)
    uri = URI.parse("#{phone_id_path('v24.0')}/media")
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{whatsapp_channel.provider_config['api_key']}"
    request.set_form(
      [
        %w[messaging_product whatsapp],
        ['type', content_type],
        ['file', file, { filename: File.basename(file.path), content_type: content_type }]
      ],
      'multipart/form-data'
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
    parse_upload_response(response)
  end

  def toggle_typing_status(typing_status, last_message:, **)
    return false unless [Events::Types::CONVERSATION_TYPING_ON, Events::Types::CONVERSATION_RECORDING].include?(typing_status)

    response = HTTParty.post(
      "#{phone_id_path('v23.0')}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        message_id: last_message.source_id,
        status: 'read',
        # NOTE: API currently only supports "typing", no "recording" status.
        typing_indicator: { type: 'text' }
      }.to_json,
      **GRAPH_REQUEST_OPTIONS
    )

    Rails.logger.error(response.parsed_response) unless response.success?

    response.success?
  end

  def read_messages(messages, **)
    # NOTE: Marking the last message as read automatically applies to all previous ones.
    message = messages.last
    response = HTTParty.post(
      "#{phone_id_path('v23.0')}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        message_id: message.source_id,
        status: 'read'
      }.to_json,
      **GRAPH_REQUEST_OPTIONS
    )

    Rails.logger.error(response.parsed_response) unless response.success?

    response.success?
  end

  private

  # Only saves dropping the embedded_signup source marker are transfer attempts; creation/rotation failures are setup errors. Returns false.
  def phone_number_belongs_to_waba?(config)
    url = "#{business_account_path}/phone_numbers?fields=id&limit=100&access_token=#{config['api_key']}"
    response = credential_check_request { HTTParty.get(url, **GRAPH_REQUEST_OPTIONS) }
    ensure_credential_verdict!(response)
    return log_transfer_failure('phone_number_id_check', response) unless response.success?

    body = credential_check_body(response)
    ids = body.is_a?(Hash) ? Array(body['data']) : []
    return true if ids.any? { |number| number['id'] == config['phone_number_id'].to_s }

    log_transfer_failure('phone_number_id_check', response)
  end

  # Checked when either half changes: a token from another Meta app would leave the inbox
  # verifying webhooks with a secret that app does not sign them with.
  def app_secret_matches_token?(config)
    stored = whatsapp_channel.provider_config_was.to_h
    return true if config['app_secret'].blank?
    return true if config['app_secret'] == stored['app_secret'] && config['api_key'] == stored['api_key']

    credential_check_request { Whatsapp::FacebookApiClient.new(config['api_key']).app_secret_matches?(config['app_secret']) }
  end

  def log_transfer_failure(check, response)
    return false unless whatsapp_channel.embedded_to_manual_transfer_pending?

    error_message = refusal_body_error_message(response)
    Rails.logger.warn("[WHATSAPP_EMBEDDED_TO_MANUAL] failure account_id=#{whatsapp_channel.account_id} channel_id=#{whatsapp_channel.id} " \
                      "check=#{check} http_status=#{response.code} meta_error=#{error_message}")
    false
  end

  # The verdict is already a refusal by the time this runs, and a log line about it must not overturn
  # it: an unreadable 401 body used to raise here and turn a recognised refusal into a 500.
  def refusal_body_error_message(response)
    body = credential_check_body(response)
    body.is_a?(Hash) ? body.dig('error', 'message') : nil
  rescue Whatsapp::CredentialCheck::Unavailable
    nil
  end

  def csat_template_service
    @csat_template_service ||= Whatsapp::CsatTemplateService.new(whatsapp_channel)
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end

  # TODO: See if we can unify the API versions and for both paths and make it consistent with out facebook app API versions
  def phone_id_path(version = 'v13.0')
    "#{api_base_path}/#{version}/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def business_account_path
    "#{api_base_path}/v14.0/#{whatsapp_channel.provider_config['business_account_id']}"
  end

  def send_text_message(phone_number, message)
    response = post_outgoing(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        context: whatsapp_reply_context(message),
        **recipient_params(phone_number),
        text: { body: message.outgoing_content },
        type: 'text'
      }.to_json
    )

    process_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = build_attachment_content(type, attachment, message)
    response = post_outgoing(
      "#{phone_id_path('v24.0')}/messages",
      headers: api_headers,
      body: {
        :messaging_product => 'whatsapp',
        :context => whatsapp_reply_context(message),
        **recipient_params(phone_number),
        'type' => type,
        type.to_s => type_content
      }.to_json
    )

    process_response(response, message)
  end

  def error_message(response)
    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/#sample-response
    response.parsed_response.dig('error', 'message') if response.parsed_response.is_a?(Hash)
  end

  def parse_upload_response(response)
    body = parse_json(response.body)
    return body['id'] if body['id'].present?

    error = body['error'] || {}
    # An API having a bad minute is not a file it refuses. Answering with MediaUploadError would be
    # indistinguishable from a rejected file and would fail the message for good; letting these through
    # keeps Sidekiq's retry. The HTTP status alone can't tell the two apart, because Graph reports
    # throttling and other transient conditions inside a 400 envelope flagged `is_transient`.
    response.value if transient_upload_error?(response, error)

    # The generic `error.message` for a rejected upload is just "(#100) Invalid parameter"; the reason
    # an agent can act on ("File Too Large", unsupported format) is in `error_data.details`.
    raise CustomExceptions::Whatsapp::MediaUploadError,
          "Media upload failed: #{error.dig('error_data', 'details') || error['message'] || "HTTP #{response.code}"}"
  end

  def transient_upload_error?(response, error)
    response.code == '429' || response.is_a?(Net::HTTPServerError) || error['is_transient'] == true
  end

  def parse_json(body)
    JSON.parse(body.to_s)
  rescue JSON::ParserError
    {}
  end

  def voice_message?(type, attachment)
    return false unless type == 'audio' && VOICE_MESSAGE_CONTENT_TYPES.include?(voice_content_type(attachment))

    # `is_recorded_audio` is the legacy fazer.ai meta key (transcode pipeline and old messages).
    (attachment.meta&.dig('is_voice_message') || attachment.meta&.dig('is_recorded_audio')).present?
  end

  # A browser can hand ActiveStorage a type carrying parameters (`audio/ogg; codecs=opus`), and the
  # blob keeps it verbatim. Compare the media type alone, or a recording made in Chrome misses the
  # list it belongs to.
  def voice_content_type(attachment)
    attachment.file.content_type.to_s.split(';').first.to_s.strip.downcase
  end

  def build_attachment_content(type, attachment, message)
    # Referencing uploaded media by id avoids Meta's fwdproxy download, which is rate limited per ASN (error 131053).
    type_content = Whatsapp::MediaUploadService.new(whatsapp_channel, attachment).perform || { 'link' => attachment.download_url }
    type_content['caption'] = message.outgoing_content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename if type == 'document'
    type_content['voice'] = true if voice_message?(type, attachment)
    type_content
  end

  def template_body_parameters(template_info)
    template_body = {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      }
    }

    # Enhanced template parameters structure
    # Note: Legacy format support (simple parameter arrays) has been removed
    # in favor of the enhanced component-based structure that supports
    # headers, buttons, and authentication templates.
    #
    # Expected payload format from frontend:
    # {
    #   processed_params: {
    #     body: { '1': 'John', '2': '123 Main St' },
    #     header: {
    #       media_url: 'https://...',
    #       media_type: 'image',
    #       media_name: 'filename.pdf' # Optional, for document templates only
    #     },
    #     buttons: [{ type: 'url', parameter: 'otp123456' }]
    #   }
    # }
    # This gets transformed into WhatsApp API component format:
    # [
    #   { type: 'body', parameters: [...] },
    #   { type: 'header', parameters: [...] },
    #   { type: 'button', sub_type: 'url', parameters: [...] }
    # ]
    template_body[:components] = template_info[:parameters] || []

    template_body
  end

  def whatsapp_reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    return nil if reply_to.blank?

    {
      message_id: reply_to
    }
  end

  def send_interactive_text_message(phone_number, message)
    payload = create_payload_based_on_items(message)

    response = post_outgoing(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        **recipient_params(phone_number),
        interactive: payload,
        type: 'interactive'
      }.to_json
    )

    process_response(response, message)
  end

  def send_reaction_message(phone_number, message)
    response = post_outgoing(
      "#{phone_id_path('v23.0')}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        recipient_type: 'individual',
        to: phone_number,
        type: 'reaction',
        reaction: {
          message_id: message.content_attributes[:in_reply_to_external_id],
          emoji: message.outgoing_content
        }
      }.to_json
    )

    process_response(response, message)
  end

  # Every HTTP call that puts a message on its way out goes through here, and nothing else does.
  # One line inside the `rescue`, on purpose: see Whatsapp::TransportFailure.
  #
  # The ceiling lives here rather than at each call site, and AFTER the forwarded keywords, so a
  # send cannot be added without one and a caller cannot quietly raise it. Same arrangement as the
  # Baileys provider's `post_send_message`.
  def post_outgoing(url, **)
    HTTParty.post(url, **, **GRAPH_REQUEST_OPTIONS)
  rescue StandardError => e
    raise_transport_failure(e)
  end
end

Whatsapp::Providers::WhatsappCloudService.prepend_mod_with('Whatsapp::Providers::WhatsappCloudService')
