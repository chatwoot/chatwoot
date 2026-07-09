# Handles the WhatsApp Coexistence `history` webhook: a 6-month backfill of past 1:1 chats
# delivered in phases/chunks after onboarding. This has its OWN normalizer and does NOT reuse
# IncomingMessageBaseService, because the history payload shape (history[] -> threads[] ->
# messages[] with from/to-derived direction) is fundamentally different from live webhooks.
#
# Guarantees:
# - Idempotent: dedupe by source_id (wamid). Re-delivered chunks (Meta retries on non-2xx and
#   chunks may arrive out of order/repeated) are a no-op because every message is skipped.
# - Historical timestamps: created_at is set from the message's original unix timestamp.
# - No new-message side effects: messages are marked content_attributes[:history_import] so
#   Message#execute_after_create_commit_callbacks skips notifications/automation/webhooks/SendReply.
# - Best-effort & crash-safe: malformed chunks/messages are logged and skipped, never raised,
#   so the webhook always returns 2xx (a 500 would make Meta retry the whole chunk).
#
# Media limitation (documented): history media messages arrive WITHOUT a downloadable asset id
# (the id, when it exists, comes in a separate later webhook and only for media <=14 days old).
# We therefore persist media history as a text placeholder — no attachment download is attempted.
# https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/reference/history
class Whatsapp::HistoryMessageService
  TEXT_TYPES = %w[text button].freeze

  def initialize(inbox:, params:)
    @inbox = inbox
    @params = params
  end

  # Serialization against concurrent redelivery of the same chunk (Meta retries on non-2xx) is
  # the caller's (Webhooks::WhatsappEventsJob) responsibility via the per-inbox
  # WHATSAPP_HISTORY_SYNC_MUTEX lock, so a lock conflict raises and gets retried instead of
  # silently dropping the chunk. The source_id dedupe check below is the second line of defense.
  def perform
    return unless Whatsapp::HistorySync.enabled?

    process_history
  rescue StandardError => e
    # Never 500 back to Meta — that would retry the whole chunk. Log and move on.
    Rails.logger.error("[WHATSAPP] History import failed for inbox #{@inbox&.id}: #{e.message}")
  end

  private

  def process_history
    value = @params.dig(:entry, 0, :changes, 0, :value) || {}
    business_phone = phone_digits(value.dig(:metadata, :display_phone_number))

    Array(value[:history]).each do |chunk|
      process_chunk(chunk, business_phone)
    end
  end

  def process_chunk(chunk, business_phone)
    phase = chunk.dig(:metadata, :phase)
    Array(chunk[:threads]).each do |thread|
      process_thread(thread, business_phone, phase)
    end
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] History chunk skipped for inbox #{@inbox.id}: #{e.message}")
  end

  def process_thread(thread, business_phone, phase)
    contact_phone = thread[:id].to_s
    return if contact_phone.blank?

    contact_inbox = resolve_contact_inbox(contact_phone)
    return if contact_inbox.blank?

    conversation = find_or_create_conversation(contact_inbox)
    Array(thread[:messages]).each do |message|
      import_message(message, conversation, contact_inbox.contact, business_phone, phase)
    end
  end

  def import_message(message, conversation, contact, business_phone, phase)
    source_id = message[:id].to_s
    return if source_id.blank?
    return if Message.find_by(source_id: source_id).present? # dedupe repeated/out-of-order chunks

    outgoing = phone_digits(message[:from]) == business_phone
    conversation.messages.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: outgoing ? :outgoing : :incoming,
      status: outgoing ? :delivered : :read,
      sender: outgoing ? nil : contact,
      source_id: source_id,
      content: message_content(message),
      created_at: message_timestamp(message),
      content_attributes: build_content_attributes(message, phase)
    )
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] History message skipped (source_id=#{message[:id]}): #{e.message}")
  end

  # String keys on purpose: Message#execute_after_create_commit_callbacks reads
  # content_attributes['history_import'] on the in-memory record (not reloaded), so the key
  # must already be a String for the side-effect guard to match.
  def build_content_attributes(message, phase)
    attrs = { 'history_import' => true, 'history_phase' => phase }
    ts = message[:timestamp]
    attrs['external_created_at'] = ts.to_i if ts.present?
    attrs['is_history_media_placeholder'] = true unless TEXT_TYPES.include?(message[:type])
    attrs
  end

  # Text carries its body; every other type is a placeholder because history media has no
  # downloadable id inline. Show the caption when present, otherwise a generic placeholder.
  def message_content(message)
    return message.dig(:text, :body) if message[:type] == 'text'
    return message.dig(:button, :text) if message[:type] == 'button'

    caption = message.dig(message[:type].to_s.to_sym, :caption)
    caption.presence || I18n.t('conversations.messages.whatsapp.unsupported_message')
  end

  def message_timestamp(message)
    ts = message[:timestamp]
    ts.present? ? Time.zone.at(ts.to_i) : Time.current
  end

  def resolve_contact_inbox(contact_phone)
    source_id = Whatsapp::PhoneNumberNormalizationService.new(@inbox)
                                                         .normalize_and_find_contact_by_provider(contact_phone, :cloud)
    ContactInboxSourceIdResolver.new(
      inbox: @inbox,
      source_ids: [source_id],
      contact_attributes: contact_attributes(contact_phone)
    ).perform
  end

  def contact_attributes(contact_phone)
    digits = phone_digits(contact_phone)
    return { name: contact_phone } if digits.blank?

    { name: "+#{digits}", phone_number: "+#{digits}" }
  end

  # Group the whole thread into the latest open conversation, else create one.
  # String key on purpose: Conversation#notify_conversation_creation reads
  # additional_attributes['history_import'] on the in-memory record (not reloaded), so the guard
  # that suppresses CONVERSATION_CREATED for imported conversations only matches a String key.
  def find_or_create_conversation(contact_inbox)
    existing = if @inbox.lock_to_single_conversation
                 contact_inbox.conversations.last
               else
                 contact_inbox.conversations.where.not(status: :resolved).last
               end
    return existing if existing

    ::Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: { 'history_import' => true }
    )
  end

  def phone_digits(identifier)
    identifier.to_s.gsub(/\D/, '').presence
  end
end
