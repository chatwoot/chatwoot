class Whatsapp::Providers::WhatsappZapiService < Whatsapp::Providers::BaseService # rubocop:disable Metrics/ClassLength
  include Whatsapp::TransportFailure
  include Whatsapp::CredentialCheck
  include Whatsapp::ZapiRequestOptions

  # See the note in WhatsappBaileysService: legacy errors share the session hierarchy.
  class ProviderUnavailableError < Whatsapp::Session::Errors::ProviderUnavailable; end
  class InstanceChangedError < StandardError; end

  API_BASE_PATH = 'https://api.z-api.io'.freeze
  CALLBACK_URL_FIELDS = %w[receivedCallbackUrl deliveryCallbackUrl messageStatusCallbackUrl connectedCallbackUrl
                           disconnectedCallbackUrl presenceChatCallbackUrl initialDataCallbackUrl].freeze

  def send_template(phone_number, template_info); end

  def sync_templates; end

  def send_message(phone, message)
    phone = phone.delete('+')
    params = message.content_attributes[:zapi_args].presence || {}

    params[:messageId] = message.in_reply_to_external_id if message.in_reply_to_external_id.present?

    if message.content_attributes[:is_reaction]
      send_reaction_message(phone, message, **params)
    elsif message.attachments.present?
      handle_message_with_attachment(message, phone, **params)
    elsif message.outgoing_content.present?
      send_text_message(phone, message, **params)
    else
      message.update!(is_unsupported: true)
      nil
    end
  end

  def validate_provider_config?
    url = "#{api_instance_path_with_token}/status"
    headers = api_headers
    response = credential_check_request { HTTParty.get(url, headers: headers, **ZAPI_REQUEST_OPTIONS) }
    ensure_credential_verdict!(response)

    process_response(response)
  end

  def setup_channel_provider
    register_webhooks

    if whatsapp_channel.provider_connection.blank? || whatsapp_channel.provider_connection['connection'] == 'close'
      Channels::Whatsapp::ZapiQrCodeJob.perform_later(whatsapp_channel)
    end

    true
  end

  # Z-API signs nothing and echoes no secret back, so the URL it posts to is the credential.
  # The token is stored before Z-API hears of it, because a registration Z-API applied but
  # whose answer never arrived would otherwise leave Z-API posting a token this app does not
  # know. The old URL stays open for the inbox until the instance it points at has confirmed
  # the new one, by accepting it here or by its first delivery (Webhooks::Whatsapp::ZapiController),
  # so a failed registration costs nothing and a new instance starts on the old URL again.
  # An inbox from before this URL existed gets its token here too, which is how
  # Migration::ZapiWebhookUrlJob moves it.
  #
  # The instance is the one the row names once locked, and that same one is written to and
  # confirmed: credentials changed in between must not split the two. `expected_instance` is for
  # the migration, which checked one instance's webhooks and must not overwrite another's.
  def register_webhooks(expected_instance: nil)
    with_registration_lock { register_current_webhook_url(expected_instance) }
  end

  # A token that leaked (a proxy log, a support ticket) is replaced by a new URL. The one being
  # replaced keeps working until Z-API is known to post to the new one: an answer to the
  # registration, or a delivery carrying the new token (Webhooks::Whatsapp::ZapiController). A
  # registration that fails therefore leaves the inbox receiving on the old URL, not silent.
  #
  # A rotation that was never confirmed is retried with the token it already made, not a new
  # one: Z-API may have taken that URL with its answer lost on the way, and both of the URLs it
  # may be posting to stay open until it is known which.
  def rotate_webhook_url
    with_registration_lock do
      update_provider_config do |config|
        next config if config['previous_webhook_verify_token'].present?

        config.merge('previous_webhook_verify_token' => config['webhook_verify_token'], 'webhook_verify_token' => SecureRandom.hex(16)).compact
      end
      register_webhooks
    end
  end

  # Only once the token that proved Z-API moved is still the current one: a rotation in between
  # made a newer one, and the URL Z-API may still use is not this one.
  def retire_previous_webhook_token(token)
    return if whatsapp_channel.provider_config['previous_webhook_verify_token'].blank?

    update_provider_config do |config|
      config['webhook_verify_token'] == token ? config.except('previous_webhook_verify_token') : config
    end
  end

  # Z-API keeps one URL per event, and update-every-webhooks overwrites all of them. Before the
  # migration does that on its own, it checks they all still point at the URL this app registered
  # (the phone-number one): an instance that sends an event somewhere else, or that another
  # installation set up, is not this app's to take over.
  def webhooks_on_legacy_url?
    response = HTTParty.get("#{api_instance_path_with_token}/me", headers: api_headers, **ZAPI_REQUEST_OPTIONS)
    raise ProviderUnavailableError unless process_response(response)

    # In case Z-API keeps the number's `+` as `%2B`.
    urls = response.parsed_response.to_h.slice(*CALLBACK_URL_FIELDS).values.compact_blank.map { |url| url.gsub(/%2B/i, '+') }
    urls.present? && urls.all?(legacy_webhook_url)
  end

  def webhook_url_confirmed?
    config = whatsapp_channel.provider_config
    config['webhook_url_confirmed_for'].present? && config['webhook_url_confirmed_for'] == config['instance_id']
  end

  # Only for the instance the inbox points at when the row is locked: an answer or a delivery
  # from an instance the inbox has since left proves nothing about the one it uses now.
  def confirm_webhook_url(instance_id)
    return if instance_id.blank? || webhook_url_confirmed?

    update_provider_config do |config|
      config['instance_id'] == instance_id ? config.merge('webhook_url_confirmed_for' => instance_id) : config
    end
  end

  def disconnect_channel_provider
    response = HTTParty.get(
      "#{api_instance_path_with_token}/disconnect",
      headers: api_headers,
      **ZAPI_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def qr_code_image
    response = HTTParty.get(
      "#{api_instance_path_with_token}/qr-code/image",
      headers: api_headers,
      **ZAPI_REQUEST_OPTIONS
    )

    if response.parsed_response['connected']
      whatsapp_channel.update_provider_connection!(connection: 'open')
      return
    end

    return unless process_response(response)

    response.parsed_response['value']
  end

  def read_messages(messages, recipient_id:, **)
    phone = recipient_id.delete('+')

    messages.each do |message|
      next if message.source_id.blank?

      Channels::Whatsapp::ZapiReadMessageJob.perform_later(whatsapp_channel, phone, message.source_id)
    end

    true
  end

  def send_read_message(phone, message_source_id)
    response = HTTParty.post(
      "#{api_instance_path_with_token}/read-message",
      headers: api_headers,
      body: {
        phone: phone,
        messageId: message_source_id
      }.to_json,
      **ZAPI_REQUEST_OPTIONS
    )

    process_response(response)
  end

  # Takes `deadline:` like the other providers and has no longer ceiling to shorten.
  def on_whatsapp(phone_number, **)
    response = HTTParty.get(
      "#{api_instance_path_with_token}/phone-exists/#{phone_number.delete('+')}",
      headers: api_headers,
      **ZAPI_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response || { 'exists' => false, 'phone' => nil, 'lid' => nil }
  end

  def delete_message(recipient_id, message)
    return false if recipient_id.blank?

    phone = recipient_id.delete('+')

    response = HTTParty.delete(
      "#{api_instance_path_with_token}/messages",
      headers: api_headers,
      query: {
        messageId: message.source_id,
        phone: phone,
        owner: message.message_type == 'outgoing'
      },
      **ZAPI_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  private

  def legacy_webhook_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{whatsapp_channel.phone_number}"
  end

  def webhook_url(token)
    "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/zapi/#{whatsapp_channel.id}/#{token}"
  end

  def register_current_webhook_url(expected_instance)
    token = reserve_webhook_verify_token
    instance = whatsapp_channel.provider_config.slice('instance_id', 'token')
    raise InstanceChangedError if expected_instance && instance != expected_instance

    response = HTTParty.put(
      "#{API_BASE_PATH}/instances/#{instance['instance_id']}/token/#{instance['token']}/update-every-webhooks",
      headers: api_headers,
      body: {
        value: webhook_url(token),
        notifySentByMe: true
      }.to_json,
      **ZAPI_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    retire_previous_webhook_token(token)
    confirm_webhook_url(instance['instance_id'])
  end

  # One registration at a time per inbox, from the token it reads to Z-API's answer: the row lock
  # covers the writes, not the order in which PUTs reach Z-API, and a setup that read a token
  # before a rotation would otherwise register it after the rotation retired it, leaving Z-API on
  # a URL this app refuses. A session lock rather than a transaction, so the token a registration
  # stores is visible to the deliveries that may arrive before Z-API answers. Reentrant, which
  # is what lets a rotation hold it around its own registration.
  def with_registration_lock
    lock_args = ['zapi_webhook_registration', whatsapp_channel.id]
    connection = ActiveRecord::Base.connection
    connection.execute(ActiveRecord::Base.sanitize_sql_array(['SELECT pg_advisory_lock(hashtext(?), ?)', *lock_args]))
    begin
      yield
    ensure
      connection.execute(ActiveRecord::Base.sanitize_sql_array(['SELECT pg_advisory_unlock(hashtext(?), ?)', *lock_args]))
    end
  end

  # Under the row lock, so a migration and a setup racing on the same inbox settle on one token.
  def reserve_webhook_verify_token
    update_provider_config do |config|
      config['webhook_verify_token'].present? ? config : config.merge('webhook_verify_token' => SecureRandom.hex(16))
    end
    whatsapp_channel.provider_config['webhook_verify_token']
  end

  # Merged into the row as it is under the lock, not into the copy this service was handed,
  # so a credential edit saved in between is not written over.
  def update_provider_config
    whatsapp_channel.with_lock do
      updated = yield whatsapp_channel.provider_config
      next if updated == whatsapp_channel.provider_config

      whatsapp_channel.provider_config = updated
      whatsapp_channel.save!(validate: false)
    end
  end

  def api_instance_path
    "#{API_BASE_PATH}/instances/#{whatsapp_channel.provider_config['instance_id']}"
  end

  def api_instance_path_with_token
    "#{api_instance_path}/token/#{whatsapp_channel.provider_config['token']}"
  end

  def api_headers
    { 'Content-Type' => 'application/json', 'Client-Token' => whatsapp_channel.provider_config['client_token'] }
  end

  def process_response(response)
    Rails.logger.error response.body unless response.success?
    response.success?
  end

  def send_text_message(phone, message, **params)
    response = post_outgoing(
      "#{api_instance_path_with_token}/send-text",
      headers: api_headers,
      body: {
        phone: phone,
        message: message.outgoing_content,
        **params
      }.compact.to_json
    )

    unless process_response(response)
      message.update!(status: :failed, external_error: response.parsed_response&.dig('error'))
      raise ProviderUnavailableError
    end

    response.parsed_response&.dig('messageId')
  end

  def handle_message_with_attachment(message, phone, **params)
    attachment = message.attachments.first

    if attachment.file.byte_size > max_size(attachment)
      message.update!(status: :failed, external_error: 'File too large')
      return
    end

    base64_data = attachment_to_base64(attachment)
    buffer = "data:#{attachment.file.content_type};base64,#{base64_data}"

    case attachment.file_type
    when 'image'
      send_image_message(phone, message, buffer, **params)
    when 'audio'
      send_audio_message(phone, message, buffer, **params)
    when 'file'
      send_document_message(phone, message, attachment, buffer, **params)
    when 'video'
      send_video_message(phone, message, buffer, **params)
    end
  end

  def max_size(attachment)
    case attachment.file_type
    when 'image'
      5.megabytes
    when 'audio', 'video'
      16.megabytes
    else
      100.megabytes
    end
  end

  def send_image_message(phone, message, buffer, **params)
    response = post_outgoing(
      "#{api_instance_path_with_token}/send-image",
      headers: api_headers,
      body: {
        phone: phone,
        image: buffer,
        caption: message.outgoing_content,
        **params
      }.compact.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('messageId')
  end

  def send_audio_message(phone, _message, buffer, **params)
    response = post_outgoing(
      "#{api_instance_path_with_token}/send-audio",
      headers: api_headers,
      body: {
        phone: phone,
        audio: buffer,
        waveform: true,
        **params
      }.compact.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('messageId')
  end

  def send_document_message(phone, message, attachment, buffer, **params)
    file_extension = File.extname(attachment.file.filename.to_s).delete('.')
    if file_extension.blank?
      Rails.logger.warn "Missing file extension for attachment: #{attachment.id}"
      file_extension = 'bin'
    end

    response = post_outgoing(
      "#{api_instance_path_with_token}/send-document/#{file_extension}",
      headers: api_headers,
      body: {
        phone: phone,
        document: buffer,
        fileName: attachment.file.filename.to_s,
        caption: message.outgoing_content,
        **params
      }.compact.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('messageId')
  end

  def send_video_message(phone, message, buffer, **params)
    response = post_outgoing(
      "#{api_instance_path_with_token}/send-video",
      headers: api_headers,
      body: {
        phone: phone,
        video: buffer,
        caption: message.outgoing_content,
        **params
      }.compact.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('messageId')
  end

  def send_reaction_message(phone, message, **params)
    response = post_outgoing(
      "#{api_instance_path_with_token}/send-reaction",
      headers: api_headers,
      body: {
        phone: phone,
        reaction: message.outgoing_content,
        messageId: message.in_reply_to_external_id,
        **params
      }.compact.to_json
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('messageId')
  end

  # Every HTTP call that puts a message on its way out goes through here, and nothing else does.
  # One line inside the `rescue`, on purpose: see Whatsapp::TransportFailure.
  def post_outgoing(url, **)
    HTTParty.post(url, **, **ZAPI_SEND_OPTIONS)
  rescue StandardError => e
    raise_transport_failure(e)
  end
end
