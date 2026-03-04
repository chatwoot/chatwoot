# Processes WhatsApp Business App history webhooks (Coexistence feature).
# History webhooks contain up to 180 days of past message threads, delivered in 3 phases:
#   Phase 0: day 0 → day 1 (most recent)
#   Phase 1: day 1 → day 90
#   Phase 2: day 90 → day 180
#
# Each phase may have multiple chunks ordered by `chunk_order`.
# `progress: 100` means synchronization is complete.
#
# Reference: https://developers.facebook.com/documentation/business-messaging/whatsapp/embedded-signup/onboarding-business-app-users
class Whatsapp::HistorySyncService
  def initialize(inbox:, params:)
    @inbox = inbox
    @channel = inbox.channel
    @account = inbox.account
    @params = params
  end

  def perform
    history_data = extract_history_data
    return if history_data.blank?

    if history_declined?(history_data)
      log_history_declined
      return
    end

    process_history_threads(history_data)
    update_sync_progress(history_data)
  end

  private

  # Reads a key from a hash that may have string or symbol keys
  def flex(hash, key)
    hash[key.to_sym] || hash[key.to_s]
  end

  def extract_history_data
    @params.dig(:entry, 0, :changes, 0, :value, :history) ||
      @params.dig(:entry, 0, 'changes', 0, 'value', 'history')
  end

  def history_declined?(history_data)
    history_data.is_a?(Array) && history_data.first&.dig(:errors).present?
  end

  def log_history_declined
    Rails.logger.info "[WHATSAPP COEXISTENCE] Business declined history sharing for channel #{@channel.phone_number}"
    update_provider_config('history_sync_status', 'declined')
  end

  def process_history_threads(history_data)
    history_data.each do |history_entry|
      threads = flex(history_entry, :threads)
      next if threads.blank?

      threads.each { |thread| process_thread(thread) }
    end
  end

  def process_thread(thread)
    contact_phone = flex(thread, :id)
    messages = flex(thread, :messages)
    return if contact_phone.blank? || messages.blank?

    contact_inbox = find_or_create_contact(contact_phone)
    return unless contact_inbox

    conversation = find_or_create_conversation(contact_inbox)
    messages.each { |msg| import_message(conversation, msg, contact_inbox.contact) }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP COEXISTENCE] Error processing thread #{contact_phone}: #{e.message}"
  end

  def find_or_create_contact(phone_number)
    normalized_phone = phone_number.start_with?('+') ? phone_number : "+#{phone_number}"

    ::ContactInboxWithContactBuilder.new(
      source_id: phone_number, inbox: @inbox,
      contact_attributes: { name: normalized_phone, phone_number: normalized_phone }
    ).perform
  end

  def find_or_create_conversation(contact_inbox)
    existing = if @inbox.lock_to_single_conversation
                 contact_inbox.conversations.last
               else
                 contact_inbox.conversations.where.not(status: :resolved).last
               end

    existing || ::Conversation.create!(
      account_id: @account.id, inbox_id: @inbox.id,
      contact_id: contact_inbox.contact.id, contact_inbox_id: contact_inbox.id
    )
  end

  def import_message(conversation, message, contact)
    source_id = flex(message, :id)
    msg_type = flex(message, :type)
    return if source_id.blank? || msg_type == 'media_placeholder'
    return if Message.exists?(source_id: source_id)

    build_and_save_message(conversation, message, contact, source_id, msg_type)
  rescue ActiveRecord::RecordNotUnique
    nil
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP COEXISTENCE] Error importing message #{source_id}: #{e.message}"
  end

  def build_and_save_message(conversation, message, contact, source_id, msg_type)
    is_outgoing = flex(message, :from) == @channel.phone_number.delete('+')
    timestamp = flex(message, :timestamp)

    msg = conversation.messages.create!(
      content: extract_message_content(message, msg_type),
      account_id: @account.id, inbox_id: @inbox.id,
      message_type: is_outgoing ? :outgoing : :incoming,
      status: map_status(flex(message, :status)),
      sender: is_outgoing ? nil : contact,
      source_id: source_id,
      content_attributes: { imported_from_history: true },
      created_at: timestamp ? Time.zone.at(timestamp.to_i) : Time.current
    )

    download_and_attach_media(msg, message, msg_type) if media_message_type?(msg_type)
  end

  def extract_message_content(message, msg_type)
    content_obj = message[msg_type.to_sym] || message[msg_type]
    return '' if content_obj.blank?

    extract_content_by_type(content_obj, msg_type)
  end

  CAPTION_TYPES = %w[image video document audio voice].freeze
  MEDIA_TYPES = %w[image audio video voice document sticker].freeze

  def extract_content_by_type(content_obj, msg_type)
    return flex(content_obj, :body).to_s if msg_type == 'text'
    return flex(content_obj, :caption).to_s if CAPTION_TYPES.include?(msg_type)
    return format_location(content_obj) if msg_type == 'location'
    return format_contact(content_obj) if msg_type == 'contacts'

    ''
  end

  def format_location(obj)
    name = flex(obj, :name)
    name ? "#{name}, #{flex(obj, :address)}" : ''
  end

  def format_contact(obj)
    obj.is_a?(Array) ? obj.first&.dig(:name, :formatted_name).to_s : ''
  end

  def download_and_attach_media(message_record, message_data, msg_type)
    attachment_data = message_data[msg_type.to_sym] || message_data[msg_type]
    media_id = attachment_data && flex(attachment_data, :id)
    return if media_id.blank?

    file = fetch_media_file(media_id)
    return if file.blank?

    message_record.attachments.create!(
      account_id: @account.id, file_type: file_content_type(msg_type),
      file: { io: file, filename: file.original_filename, content_type: file.content_type }
    )
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP COEXISTENCE] Error downloading attachment for #{media_id}: #{e.message}"
  end

  def fetch_media_file(media_id)
    url_response = HTTParty.get(@channel.media_url(media_id), headers: @channel.api_headers)
    return unless url_response.success?

    Down.download(url_response.parsed_response['url'], headers: @channel.api_headers)
  end

  def media_message_type?(msg_type)
    MEDIA_TYPES.include?(msg_type)
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if file_type == 'video'

    :file
  end

  def map_status(status)
    { 'read' => :read, 'delivered' => :delivered, 'sent' => :sent, 'failed' => :failed, 'error' => :failed }
      .fetch(status&.downcase, :sent)
  end

  def update_sync_progress(history_data)
    metadata = flex(history_data.first, :metadata)
    return unless metadata

    progress = flex(metadata, :progress)
    phase = flex(metadata, :phase)
    completed = progress.to_i >= 100

    update_provider_config('history_sync_progress', progress)
    update_provider_config('history_sync_phase', phase)
    update_provider_config('history_sync_status', completed ? 'completed' : 'in_progress')

    Rails.logger.info "[WHATSAPP COEXISTENCE] History sync #{completed ? 'completed' : "#{progress}% (phase #{phase})"} for #{@channel.phone_number}"
  end

  def update_provider_config(key, value)
    config = @channel.provider_config.dup
    config['coexistence'] ||= {}
    config['coexistence'][key] = value
    @channel.update!(provider_config: config)
  end
end
