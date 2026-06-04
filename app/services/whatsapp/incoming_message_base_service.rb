# Mostly modeled after the intial implementation of the service based on 360 Dialog
# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
class Whatsapp::IncomingMessageBaseService
  include ::Whatsapp::IncomingMessageServiceHelpers
  include ::Whatsapp::IncomingMessageIdentifierHelper

  # rubocop:disable Style/ClassVars
  @@microsecond = 0
  # rubocop:enable Style/ClassVars

  pattr_initialize [:inbox!, :params!, :outgoing_echo]

  def perform
    processed_params

    if processed_params.try(:[], :statuses).present?
      sync_contacts if processed_params.try(:[], :contacts).present?
      process_statuses
    elsif contact_sync_payload?
      sync_contacts
    elsif messages_data.present?
      process_messages
    elsif processed_params.try(:[], :contacts).present?
      sync_contacts
    end
  end

  # Returns messages array for both regular messages and echo events
  def messages_data
    @processed_params&.dig(:messages) || @processed_params&.dig(:message_echoes)
  end

  private

  def process_messages
    # We don't support reactions & ephemeral message now, we need to skip processing the message
    # if the webhook event is a reaction or an ephermal message or an unsupported message.
    return if unprocessable_message_type?(message_type)

    # Multiple webhook events can be received for the same message due to
    # misconfigurations in the Meta business manager account.
    # We use an atomic Redis SET NX to prevent concurrent workers from both
    # processing the same message simultaneously.
    return if process_message_edit
    return if find_message_by_source_id(messages_data.first[:id])
    return unless lock_message_source_id!
    set_message_type
    set_contact
    return unless @contact
    return if @contact.blocked? && !outgoing_echo

    ActiveRecord::Base.transaction do
      set_conversation
      create_messages
    end
  end

  def process_statuses
    status = @processed_params[:statuses].first
    return unless find_message_by_source_id(status[:id])

    update_whatsapp_identifiers_from_status(status)
    update_message_with_status(@message, status)
  rescue ArgumentError => e
    Rails.logger.error "Error while processing whatsapp status update #{e.message}"
  end

  def contact_sync_payload?
    return false if processed_params.blank?
    return false if processed_params.try(:[], :contacts).blank?

    message = processed_params[:messages]&.first
    return false if message.blank?
    return false unless message[:type].to_s == 'text'

    message.dig(:text, :body).to_s.strip.casecmp('contacts.update').zero?
  end

  def sync_contacts
    processed_params[:contacts].each do |contact|
      sync_contact(contact)
    end
  end

  def sync_contact(contact_params)
    return if contact_params.blank?

    contact_attributes = {
      name: contact_display_name(contact_params),
      avatar_url: contact_params.dig(:profile, :picture).presence,
      bsuid: contact_bsuid(contact_params),
      whatsapp_username: contact_username(contact_params)
    }.compact

    waid = contact_source_id(contact_params)
    apply_phone_attributes(contact_attributes, contact_phone_identifier(contact_params))
    return if waid.blank?

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    raw_from = contact_phone_identifier(contact_params).presence || contact_bsuid(contact_params)
    update_contact_with_profile_name(contact_params, raw_from: raw_from)
    sync_group_contact(contact_params)
  end

  def sync_group_contact(contact_params)
    return if contact_params[:group_id].blank?

    ::ContactInboxWithContactBuilder.new(
      source_id: contact_params[:group_id],
      inbox: inbox,
      contact_attributes: {
        email: contact_params[:group_id],
        name: contact_params[:group_subject] || contact_params[:group_id],
        avatar_url: contact_params[:group_picture].presence
      }
    ).perform
  end

  def update_message_with_status(message, status)
    if status[:status] == 'deleted'
      content_attributes = (message.content_attributes || {}).merge(
        'deleted' => true
      )
      preserve_content = preserve_deleted_message_content?
      content_attributes['deleted_content_preserved'] = true if preserve_content
      message.assign_attributes(content_attributes: content_attributes)
      message.content = I18n.t('conversations.messages.deleted') unless preserve_content
    else
      message.status = status[:status]
    end
    if status[:status] == 'failed' && status[:errors].present?
      error = status[:errors]&.first
      message.external_error = "#{error[:code]}: #{error[:title]}"
      message.conversation.open! unless message.conversation.open?
    end
    message.save!
  end

  def preserve_deleted_message_content?
    ActiveModel::Type::Boolean.new.cast(inbox.account.show_deleted_message_content)
  end
      create_message(contact, source_id: message[:id])
      attach_contact(contact)
      @message.save!
    end
  end

  def create_regular_message(message)
    create_message(message, source_id: message[:id])
    attach_files
    attach_location if message_type == 'location'
    @message.save!
  end

  def process_message_edit
    return false unless message_edit_event?

    message = messages_data.first
    original_source_id = edited_original_source_id(message)
    unless original_source_id.present?
      Rails.logger.warn("[WHATSAPP] Message edit ignored without original context id event_id=#{message[:id]}")
      return true
    end

    original_message = find_original_message_for_edit(message, original_source_id)
    unless original_message
      Rails.logger.info("[WHATSAPP] Message edit ignored missing original original_source_id=#{original_source_id} event_id=#{message[:id]}")
      return true
    end

    edited_content = message_content(message)
    content_attrs = original_message.content_attributes || {}
    content_attrs = content_attrs.merge(
      'edited' => true,
      'edit_event_id' => message[:id],
      'edited_at' => Time.current.utc.iso8601
    )
    content_attrs['edit_timestamp'] = message[:edit_timestamp] if message[:edit_timestamp].present?
    content_attrs['previous_content'] = original_message.content if original_message.content.present? && edited_content.present? && original_message.content != edited_content

    original_message.assign_attributes(content_attributes: content_attrs)
    original_message.content = edited_content if edited_content.present?
    original_message.save!
    true
  end

  def find_original_message_for_edit(message, original_source_id)
    original_message = inbox.messages.find_by(source_id: original_source_id)
    return original_message if original_message

    set_message_type
    set_contact
    return unless @contact

    set_conversation
    candidates = @conversation.messages.chat
                              .where(message_type: @message_type)
                              .where(created_at: edit_lookup_window(message)..)
                              .where('created_at <= ?', edit_event_time(message))
                              .where.not(source_id: message[:id])
                              .order(created_at: :desc)
                              .limit(2)
                              .to_a

    return unless candidates.one?

    Rails.logger.info(
      "[WHATSAPP] Message edit recovered missing original original_source_id=#{original_source_id} event_id=#{message[:id]} message_id=#{candidates.first.id}"
    )
    candidates.first
  end

  def edit_event_time(message)
    @edit_event_time ||= {}
    @edit_event_time[message[:id]] ||= begin
      timestamp = if message[:edit_timestamp].present?
                    message[:edit_timestamp].to_f / 1000
                  else
                    message[:timestamp].presence.to_i
                  end
      timestamp.positive? ? Time.zone.at(timestamp) : Time.current
    end
  end

  def edit_lookup_window(message)
    edit_event_time(message) - 15.minutes
  end

  def message_edit_event?
    message = messages_data&.first
    message.present? && message[:message_type].to_s == 'message_edit'
  end

  def edited_original_source_id(message)
    message.dig(:context, :id).presence || message.dig(:context, :message_id).presence || message[:edited_message_id].presence
  end

  def set_contact
    if outgoing_echo
      set_contact_from_echo
    else
      set_contact_from_message
    end
  end

  def set_contact_from_echo
    # For echo messages, contact phone is in the 'to' field
    phone_number = messages_data.first[:to].to_s
    return if phone_number.blank?

    waid = processed_waid(phone_number) || phone_number

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: { name: "+#{phone_number}", phone_number: "+#{phone_number}" }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
    @sender = nil
  end

  def set_contact_from_message
    contact_params = @processed_params[:contacts]&.first
    return if contact_params.blank?

    waid = contact_source_id(contact_params)
    return if waid.blank?

    contact_attributes = {
      name: contact_display_name(contact_params),
      avatar_url: contact_params.dig(:profile, :picture).presence,
      bsuid: contact_bsuid(contact_params),
      whatsapp_username: contact_username(contact_params)
    }.compact
    apply_phone_attributes(contact_attributes, contact_phone_identifier(contact_params))

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
    @sender = webhook_outgoing_message? ? nil : contact_inbox.contact

    # Update existing contact name for LID-suffix placeholders or low-quality names
    update_contact_with_profile_name(contact_params)
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    merge_contact_conversation_aliases if single_conversation_for_contact_aliases?
    @conversation = existing_contact_conversation
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def merge_contact_conversation_aliases
    conversations = contact_conversation_aliases.to_a
    return if conversations.size <= 1

    target = preferred_contact_conversation(conversations)
    mergees = conversations - [target]
    Message.where(conversation_id: mergees.map(&:id)).update_all(conversation_id: target.id) # rubocop:disable Rails/SkipsModelValidations
    target.update_columns(last_activity_at: conversations.filter_map(&:last_activity_at).max, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    mergees.each(&:destroy!)
  end

  def existing_contact_conversation
    conversations = contact_conversation_aliases
    return conversations.last if single_conversation_for_contact_aliases?

    conversations.where.not(status: :resolved).last
  end

  def contact_conversation_aliases
    @inbox.conversations.non_group_conversations.where(contact_id: @contact.id, contact_inbox_id: contact_inbox_aliases.select(:id))
  end

  def preferred_contact_conversation(conversations)
    conversations.select { |conversation| conversation.contact_inbox.source_id.exclude?('@') }
                 .max_by { |conversation| [conversation.last_activity_at, conversation.id] } ||
      conversations.max_by { |conversation| [conversation.last_activity_at, conversation.id] }
  end

  def contact_inbox_aliases
    @contact.contact_inboxes.where(inbox_id: @inbox.id)
  end

  def single_conversation_for_contact_aliases?
    @inbox.lock_to_single_conversation
  end

  def attach_files
    return if %w[text button interactive location contacts].include?(message_type)

    attachment_payload = messages_data.first[message_type.to_sym]
    @message.content ||= attachment_payload[:caption]

    attachment_file = download_attachment_file(attachment_payload)
    return if attachment_file.blank?

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end

  def attach_location
    location = messages_data.first['location']
    location_name = location['name'] ? "#{location['name']}, #{location['address']}" : ''
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      coordinates_lat: location['latitude'],
      coordinates_long: location['longitude'],
      fallback_title: location_name,
      external_url: location['url']
    )
  end

  def create_message(message, source_id: nil)
    timestamp = message[:timestamp] ? Time.at(message[:timestamp].to_i, microsecond, :microsecond, in: 'UTC') : Time.current.utc
    Rails.logger.info("[WHATSAPP] Incoming message type=#{message_type} content_type=#{message_type == 'sticker' ? 'sticker' : 'nil'} source_id=#{message[:id]}")
    content_attrs = webhook_outgoing_message? ? { external_echo: true } : {}
    content_attrs[:in_reply_to_external_id] = @in_reply_to_external_id if @in_reply_to_external_id.present?
    content_attrs[:referral] = @referral if @referral.present?

    @message = @conversation.messages.build(
      content: message_content(message),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: webhook_outgoing_message? ? :outgoing : @message_type,
      # Set status to :delivered for echo messages to prevent SendReplyJob from trying to send them
      status: webhook_outgoing_message? ? :delivered : :sent,
      content_type: message_type == 'sticker' ? 'sticker' : nil,
      sender: webhook_outgoing_message? ? nil : @sender,
      source_id: (source_id || message[:id]).to_s,
      content_attributes: content_attrs,
      created_at: timestamp,
    )
    @message
  end

  def webhook_outgoing_message?
    outgoing_echo || @message_type == :outgoing
  end

  def attach_contact(contact)
    phones = contact[:phones]
    phones = [{ phone: 'Phone number is not available' }] if phones.blank?

    name_info = (contact[:name] || contact['name'] || {}).with_indifferent_access
    formatted_name = contact_formatted_name(name_info)
    contact_meta = {
      formattedName: formatted_name,
      firstName: name_info[:first_name].presence || name_info[:firstName],
      lastName: name_info[:last_name].presence || name_info[:lastName]
    }.compact

    update_shared_contact_name(contact, formatted_name)

    phones.each do |phone|
      @message.attachments.new(
        account_id: @message.account_id,
        file_type: file_content_type(message_type),
        fallback_title: phone[:phone].to_s,
        meta: contact_meta
      )
    end
  end

  def set_message_type
    @message_type = :incoming
  end

  def microsecond
    # rubocop:disable Style/ClassVars
    @@microsecond = 0 if @@microsecond > 999_999
    @@microsecond += 1
    @@microsecond
    # rubocop:enable Style/ClassVars
  end

  def contact_params
    @contact_params ||= @processed_params[:contacts]&.first
  end

  def lid_message?
    contact_params.present? && contact_bsuid(contact_params).present? && contact_phone_identifier(contact_params).blank?
  end

  def update_contact_with_profile_name(contact_params, raw_from: nil)
    profile_name = contact_profile_display_name(contact_params)
    return if profile_name.blank?
    return if @contact.name == profile_name

    return unless contact_name_updatable?(@contact, raw_from: raw_from)

    @contact.update!(name: profile_name)
  end

  def update_shared_contact_name(contact_payload, formatted_name)
    return if formatted_name.blank?

    normalized_contact_phone_numbers(contact_payload).each do |phone_number|
      shared_contact = Contact.find_by(account_id: @inbox.account_id, phone_number: phone_number)
      next if shared_contact.blank? || shared_contact.name == formatted_name
      next unless contact_name_updatable?(shared_contact, raw_from: phone_number)

      shared_contact.update!(name: formatted_name)
    end
  end

  def normalized_contact_phone_numbers(contact_payload)
    Array(contact_payload[:phones] || contact_payload['phones']).filter_map do |phone|
      raw_phone = (phone[:phone] || phone['phone']).to_s.gsub(/\D/, '')
      next if raw_phone.blank? || raw_phone == '0'
      next unless raw_phone.match?(/^[1-9]\d{7,14}$/)

      raw_phone = normalised_brazil_mobile_number(raw_phone) if brazil_phone_number?(raw_phone)
      waid = processed_waid(raw_phone) || raw_phone
      "+#{waid}" if waid.present?
    end.uniq
  end

  def contact_name_updatable?(contact, raw_from: nil)
    contact_name_has_lid_suffix?(contact) || contact_name_matches_phone_number?(contact, raw_from) || contact_name_low_quality?(contact)
  end

  def contact_name_matches_phone_number?(contact, raw_from = nil)
    raw_from = raw_from.presence || messages_data&.first&.[](:from).to_s
    raw_from = contact_params[:wa_id].to_s if raw_from.blank? && contact_params.present?
    return false if raw_from.blank? || raw_from.include?('@lid')

    raw_digits = raw_from.gsub(/\D/, '')
    return false if raw_digits.blank?

    phone_number = "+#{raw_digits}"
    formatted_phone_number = TelephoneNumber.parse(phone_number).international_number
    contact_name = contact.name.to_s
    contact_digits = contact_name.gsub(/\D/, '')

    contact_name == phone_number ||
      contact_name == formatted_phone_number ||
      (contact_digits.present? && contact_digits == raw_digits)
  end

  def contact_name_has_lid_suffix?(contact)
    contact.name.to_s.downcase.end_with?('@lid')
  end

  def contact_name_low_quality?(contact)
    contact_name = contact.name.to_s.strip
    return true if contact_name.blank?
    return true if contact_name.length <= 3

    contact_name.match?(/\A[^\p{L}\p{N}]+\z/)
  end

  def contact_source_id(contact_params)
    phone_identifier = contact_phone_identifier(contact_params)
    return phone_identifier if phone_identifier.present?

    contact_bsuid(contact_params)
  end

  def contact_phone_identifier(contact_params)
    raw_phone = contact_params[:wa_id].to_s
    raw_phone = contact_params.dig(:profile, :phone).to_s if raw_phone.blank? || raw_phone.include?('@lid')
    raw_phone = raw_phone.gsub(/\D/, '')
    return if raw_phone.blank? || raw_phone == '0'
    return unless raw_phone.match?(/^[1-9]\d{7,14}$/)

    processed_waid(raw_phone) || raw_phone
  end

  def apply_phone_attributes(contact_attributes, phone_identifier)
    return if phone_identifier.blank?

    phone = brazil_phone_number?(phone_identifier) ? normalised_brazil_mobile_number(phone_identifier) : phone_identifier
    contact_attributes[:phone_number] = "+#{phone}" if phone.present?
  end

  def contact_bsuid(contact_params)
    contact_params[:user_id].presence || messages_data&.first&.[](:from_user_id).presence
  end

  def contact_username(contact_params)
    contact_params.dig(:profile, :username).presence
  end

  def contact_display_name(contact_params)
    contact_params.dig(:profile, :name).presence ||
      contact_username(contact_params) ||
      contact_params[:wa_id].presence ||
      contact_bsuid(contact_params)
  end

  def contact_profile_display_name(contact_params)
    contact_params.dig(:profile, :name).presence || contact_username(contact_params)
  end
end
