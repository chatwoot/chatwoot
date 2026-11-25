module Whatsapp::IncomingMessageServiceHelpers # rubocop:disable Metrics/ModuleLength
  # How long a message stands waiting for the chat before it gives up and lets the job come
  # back for it. Sized by the album it exists for -- the sibling webhooks of one upload land
  # within a second or two of each other -- and not by how long the work behind the lock
  # takes, which is what `Locks::CHAT_LOCK_TTL` is for.
  CONTACT_LOCK_WAIT = 5.seconds

  def download_attachment_file(attachment_payload)
    Down.download(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)
  end

  def conversation_params
    params = {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
    # First-touch attribution persisted only when the conversation is created from
    # the originating message: the rich ad/post referral (externalAdReply) and/or
    # the WhatsApp entry point (e.g. click_to_chat_link from a profile/bio link).
    attribution = { referral: @referral, entry_point: @entry_point }.compact
    params[:additional_attributes] = attribution if attribution.present?
    params
  end

  def processed_params
    @processed_params ||= params
  end

  def account
    @account ||= inbox.account
  end

  def message_type
    messages_data.first[:type]
  end

  # Where a body can live, in the order WhatsApp can carry them. A message has exactly one
  # of these, so the first hit is the content.
  CONTENT_PATHS = [
    %i[text body], %i[button text], %i[interactive button_reply title],
    %i[interactive list_reply title], %i[name formatted_name], %i[reaction emoji]
  ].freeze

  def message_content(message)
    return I18n.t('conversations.messages.whatsapp.flow_response') if message.dig(:interactive, :nfm_reply).present?

    # TODO: map interactive messages back to button messages in chatwoot
    CONTENT_PATHS.lazy.filter_map { |path| message.dig(*path) }.first || referral_fallback_content(message)
  end

  # Edited messages nest the new content under `edit.message`, which carries its own
  # type. Reuse message_content for text/interactive bodies and fall back to the
  # media caption for image/video/document edits.
  def edited_message_content(edited)
    return if edited.blank?

    message_content(edited) ||
      edited.dig(:image, :caption) ||
      edited.dig(:video, :caption) ||
      edited.dig(:document, :caption)
  end

  # Ad-click webhooks can arrive with no textual body (e.g. request_welcome), so
  # fall back to the ad headline/body to keep the message renderable.
  def referral_fallback_content(message)
    ref = message[:referral]
    return if ref.blank?

    ref[:headline].presence || ref[:body].presence
  end

  # Normalizes the WhatsApp Cloud API `referral` object (sent on the first
  # message after a Click-to-WhatsApp ad click) to a provider-agnostic hash.
  def normalize_cloud_referral(message)
    ref = message[:referral]
    return if ref.blank?

    {
      source_type: ref[:source_type],
      source_id: ref[:source_id],
      source_url: ref[:source_url],
      ctwa_clid: ref[:ctwa_clid],
      title: ref[:headline],
      body: ref[:body],
      media_type: ref[:media_type]&.to_s&.downcase,
      thumbnail_url: ref[:image_url] || ref[:thumbnail_url] || ref[:video_url]
    }.compact.presence
  end

  # Normalizes the Baileys `contextInfo.externalAdReply` to the same shape as
  # `normalize_cloud_referral` so the frontend reads a single referral payload.
  def normalize_baileys_referral(context_info)
    ad = context_info&.dig(:externalAdReply)
    return if ad.blank?

    {
      source_type: ad[:sourceType],
      source_id: ad[:sourceId],
      source_url: ad[:sourceUrl],
      ctwa_clid: ad[:ctwaClid],
      title: ad[:title],
      body: ad[:body],
      media_type: baileys_media_type(ad[:mediaType]),
      thumbnail_url: ad[:thumbnailUrl]
    }.compact.presence
  end

  # Baileys serializes the externalAdReply MediaType proto enum as a number
  # (0=none, 1=image, 2=video), but some layers emit the string name instead.
  # Handle both so the frontend always gets a lowercase string.
  def baileys_media_type(value)
    return if value.nil?
    return { 0 => 'none', 1 => 'image', 2 => 'video' }[value] if value.is_a?(Integer)

    value.to_s.downcase.presence
  end

  # Lightweight WhatsApp entry-point attribution from Baileys `contextInfo`.
  # Present on first-contact messages even without an ad (e.g. a profile/bio
  # click-to-chat link reports `click_to_chat_link`). Does NOT render the ad card.
  def normalize_baileys_entry_point(context_info)
    source = context_info&.dig(:entryPointConversionSource)
    return if source.blank?

    { source: source, app: context_info[:entryPointConversionApp].presence }.compact.presence
  end

  def parse_flow_response_json(response_json)
    parsed_response = JSON.parse(response_json)
    parsed_response.is_a?(Hash) ? parsed_response : response_json
  rescue JSON::ParserError, TypeError
    response_json
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)
    return :location if ['location'].include?(file_type)
    return :contact if ['contacts'].include?(file_type)

    :file
  end

  def unprocessable_message_type?(message_type)
    %w[ephemeral request_welcome].include?(message_type)
  end

  def reaction_removal?
    message_type == 'reaction' && messages_data.first.dig(:reaction, :emoji).blank?
  end

  def processed_waid(waid)
    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(waid, :cloud)
  end

  def phone_number_candidates(phone_number)
    Whatsapp::PhoneNumberNormalizationService.new(inbox).phone_number_candidates(phone_number)
  end

  def whatsapp_phone_number(identifier)
    identifier = identifier.to_s
    return if identifier.blank?
    return unless identifier.match?(/\A\d{1,15}\z/)

    identifier
  end

  def error_webhook_event?(message)
    message.key?('errors')
  end

  def log_error(message)
    Rails.logger.warn "Whatsapp Error: #{message['errors'][0]['title']} - contact: #{message['from']}"
  end

  def process_in_reply_to(message)
    @in_reply_to_external_id = message['context']&.[]('id')
    @in_reply_to_external_id = message.dig(:reaction, :message_id) if message[:type] == 'reaction'
  end

  # Resolved when the message row is built, not when the reply id is read. This fork reads
  # that id before the conversation is chosen, because a reaction has to land in the
  # conversation of the message it annotates, and the finder searches inside a conversation.
  def in_reply_to_message_id
    return @in_reply_to_message_id if defined?(@in_reply_to_message_id)
    return @in_reply_to_message_id = nil if @in_reply_to_external_id.blank? || @conversation.blank?

    @in_reply_to_message_id = Whatsapp::InReplyToMessageFinder.new(
      conversation: @conversation,
      source_id: @in_reply_to_external_id
    ).perform&.id
  end

  def find_message_by_source_id(source_id)
    return unless source_id

    @message = inbox.messages.find_by(source_id: source_id)
  end

  def message_under_process?
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{messages_data.first[:id]}")
    Redis::Alfred.get(key)
  end

  def acquire_message_processing_lock
    return false if messages_data.blank?

    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{messages_data.first[:id]}")
    Redis::Alfred.set(key, true, nx: true, ex: 1.day)
  end

  def clear_message_source_id_from_redis
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{messages_data.first[:id]}")
    ::Redis::Alfred.delete(key)
  end

  # Lock by contact phone to prevent race conditions when multiple messages
  # from the same contact arrive simultaneously (e.g., WhatsApp albums).
  # Without this, each message could create its own conversation.
  #
  # The same lock the session layer takes, on the same key, and now through the same code:
  # two implementations of one lock is how the legacy path came to release unconditionally
  # while the session path released by token, and an overrunning worker here could delete
  # the lease an import was still writing under.
  #
  # `wait` is what this path adds and the only thing it needs of its own. It covers what
  # the lock was built for: two messages of the same chat landing together, where the first
  # is done in well under a second, and a job retry a quarter of a minute later would be
  # worse than a short park. It does not cover the other holder of the same key -- a
  # history import leases the chat for a whole batch (`Locks::IMPORT_CHAT_LOCK_TTL`), two
  # orders of magnitude longer than any wait a worker thread should sit through -- so past
  # the wait it gives up with `Locks::Busy`, which the caller retries, rather than the
  # Timeout::Error nothing was listening for that used to take the message down with it.
  def with_contact_lock(phone, wait: CONTACT_LOCK_WAIT, &)
    raise ArgumentError, 'A block is required for with_contact_lock' unless block_given?
    return yield if phone.blank?

    Whatsapp::Session::Inbound::Locks.with_chat_lock(inbox, phone, wait: wait, &)
  end
end
