# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Rails/SkipsModelValidations
class DataImports::Intercom::Importer
  PageResult = Struct.new(:next_cursor, keyword_init: true) do
    def done?
      next_cursor.blank?
    end
  end

  DEFAULT_IMPORT_TYPES = %w[contacts conversations].freeze
  PROVIDER = 'intercom'.freeze
  ALREADY_IMPORTED_ERROR_CODE = 'DataImports::Intercom::AlreadyImported'.freeze
  SKIPPED_MESSAGE_ERROR_CODE = 'DataImports::Intercom::SkippedMessage'.freeze
  TRUNCATED_PARTS_ERROR_CODE = 'DataImports::Intercom::TruncatedConversationParts'.freeze
  E164_REGEX = /\A\+[1-9]\d{1,14}\z/
  INTERCOM_NUMBER_REGEX = /\A[1-9]\d{1,14}\z/
  REGULAR_MESSAGE_PART_TYPES = %w[comment note source].freeze

  def initialize(data_import:, run_id: nil)
    @data_import = data_import
    @run_id = run_id
    @account = data_import.account
    @client = DataImports::Intercom::Client.new(access_token: data_import.access_token)
    @placeholder_inboxes = DataImports::Intercom::PlaceholderInboxBuilder.new(account: @account)
    @stats = default_stats.deep_merge(data_import.stats || {})
  end

  def perform
    return unless start!

    import_contacts if import_type?('contacts')
    import_conversations if import_type?('conversations')
    finish!
  rescue StandardError => e
    fail!(e)
    raise
  end

  def start!
    return if @data_import.reload.abandoned?

    @data_import.update!(status: :processing, started_at: @data_import.started_at || Time.current)
  end

  def finish!
    return if @data_import.reload.abandoned?

    has_failures = @data_import.import_errors.non_skip_logs.exists? || @data_import.import_errors.failed.exists?
    status = has_failures ? :completed_with_errors : :completed
    @data_import.update!(
      status: status,
      completed_at: Time.current,
      stats: @stats,
      total_records: total_processed_records,
      processed_records: total_successful_records
    )
  end

  def fail!(error)
    return if @data_import.reload.abandoned?

    record_run_error(error)
    @data_import.update!(status: :failed, last_error_at: Time.current)
  end

  def import_contacts_page(starting_after: cursor_for('contacts'))
    response = @client.list_contacts(starting_after: starting_after)
    update_stat_total('contacts', response['total_count']) if response['total_count'].present?
    Array(response['data'] || response['contacts']).each do |contact|
      break if import_stopped?

      import_contact(contact)
    end
    return PageResult.new(next_cursor: nil) if import_stopped?

    next_cursor = response.dig('pages', 'next', 'starting_after')
    update_cursor('contacts', next_cursor)
    PageResult.new(next_cursor: next_cursor)
  end

  def import_conversations_page(starting_after: cursor_for('conversations'))
    response = @client.list_conversations(starting_after: starting_after)
    update_stat_total('conversations', response['total_count']) if response['total_count'].present?
    Array(response['data'] || response['conversations']).each do |conversation_summary|
      break if import_stopped?

      import_conversation_from_summary(conversation_summary)
    end
    return PageResult.new(next_cursor: nil) if import_stopped?

    next_cursor = response.dig('pages', 'next', 'starting_after')
    update_cursor('conversations', next_cursor)
    PageResult.new(next_cursor: next_cursor)
  end

  def import_contacts?
    import_type?('contacts')
  end

  def import_conversations?
    import_type?('conversations')
  end

  def contacts_completed?
    stage_completed?('contacts')
  end

  def conversations_completed?
    stage_completed?('conversations')
  end

  def cursor_for(key)
    @data_import.cursor&.dig(key, 'starting_after')
  end

  private

  def import_contacts
    cursor = cursor_for('contacts')
    loop do
      result = import_contacts_page(starting_after: cursor)
      break if result.done?

      cursor = result.next_cursor
    end
  end

  def import_conversations
    cursor = cursor_for('conversations')
    loop do
      result = import_conversations_page(starting_after: cursor)
      break if result.done?

      cursor = result.next_cursor
    end
  end

  def import_conversation_from_summary(conversation_summary)
    source_id = source_id_for(conversation_summary)
    already_handled = item_handled?('conversation', source_id)
    item = import_item('conversation', source_id, conversation_summary)
    mapping = find_mapping('conversation', source_id)

    conversation = @client.retrieve_conversation(source_id)
    return if import_stopped?

    update_message_total(item, conversation)

    contact = import_contact(primary_conversation_contact(conversation), required_for_conversation: true)
    source_type = conversation_source_type(conversation, conversation_summary)
    inbox = @placeholder_inboxes.inbox_for(source_type)
    contact_inbox = contact_inbox_for(contact, inbox)

    mapped_conversation = mapping&.chatwoot_record
    if mapped_conversation && mapping.data_import_id != @data_import.id
      skip_already_imported_item(item, mapping, already_handled: already_handled)
      import_source_message(conversation, mapped_conversation, contact)
      import_conversation_parts(conversation, mapped_conversation, contact)
      update_conversation_activity(mapped_conversation)
      return
    end

    chatwoot_conversation = mapped_conversation || create_conversation(conversation, contact, contact_inbox, inbox, source_type)
    if mapped_conversation
      record_mapping('conversation', source_id, chatwoot_conversation, metadata: conversation_metadata(conversation, inbox, source_type))
    end
    item.update!(status: :imported, chatwoot_record_type: 'Conversation', chatwoot_record_id: chatwoot_conversation.id)
    increment_stat('conversations', 'imported') unless already_handled

    import_source_message(conversation, chatwoot_conversation, contact)
    import_conversation_parts(conversation, chatwoot_conversation, contact)
    update_conversation_activity(chatwoot_conversation)
  rescue StandardError => e
    raise if e.is_a?(DataImports::Intercom::Client::Error)

    fail_item(item, e)
  ensure
    persist_stats
  end

  def import_stopped?
    return true if @import_stopped

    @data_import.reload
    @import_stopped = @data_import.abandoned? || @data_import.completed? || @data_import.completed_with_errors? || stale_import_run?
  end

  def stale_import_run?
    active_run_id = @data_import.active_intercom_import_run_id
    @run_id.present? && active_run_id.present? && active_run_id != @run_id
  end

  def import_contact(contact_payload, required_for_conversation: false)
    source_id = source_id_for(contact_payload)
    if source_id.present? && (mapping = find_mapping('contact', source_id)) && (mapped_contact = mapping.chatwoot_record)
      return reuse_mapped_contact(contact_payload, source_id, mapping, mapped_contact)
    end

    contact_payload = retrieve_contact_payload(contact_payload)
    source_id = source_id_for(contact_payload)
    already_handled = item_handled?('contact', source_id)
    item = import_item('contact', source_id, contact_payload)
    mapping = find_mapping('contact', source_id)

    mapped_contact = mapping&.chatwoot_record
    if mapped_contact && mapping.data_import_id != @data_import.id
      skip_already_imported_item(item, mapping, already_handled: already_handled)
      return mapped_contact
    end

    contact = Contact.transaction do
      imported_contact = mapped_contact || find_existing_contact(contact_payload) || create_contact(contact_payload)
      update_existing_contact(imported_contact, contact_payload)
      record_mapping('contact', source_id, imported_contact, metadata: contact_metadata(contact_payload))
      item.update!(status: :imported, chatwoot_record_type: 'Contact', chatwoot_record_id: imported_contact.id)
      imported_contact
    end
    increment_stat('contacts', 'imported') unless already_handled
    contact
  rescue StandardError => e
    raise if e.is_a?(DataImports::Intercom::Client::Error)

    fail_item(item, e)
    raise if required_for_conversation
  ensure
    persist_stats
  end

  def retrieve_contact_payload(contact_payload)
    return contact_payload if contact_payload.blank?
    return contact_payload if contact_payload['email'].present? || contact_payload['phone'].present? || contact_payload['name'].present?
    return contact_payload if contact_payload['id'].blank?

    @client.retrieve_contact(contact_payload['id'])
  rescue DataImports::Intercom::Client::Error => e
    raise unless e.status == 404

    contact_payload
  end

  def create_contact(contact_payload)
    attrs = contact_attributes(contact_payload).merge(created_at: timestamp_for(contact_payload['created_at']), updated_at: Time.current)
    result = Contact.insert_all!([attrs], returning: %w[id])
    Contact.find(result.rows.first.first)
  rescue ActiveRecord::RecordNotUnique
    find_existing_contact(contact_payload)
  end

  def reuse_mapped_contact(contact_payload, source_id, mapping, mapped_contact)
    if mapping.data_import_id == @data_import.id
      reconcile_current_run_contact(contact_payload, source_id, mapped_contact)
      return mapped_contact
    end

    already_handled = item_handled?('contact', source_id)
    item = import_item('contact', source_id, contact_payload)
    skip_already_imported_item(item, mapping, already_handled: already_handled)
    mapped_contact
  end

  def update_existing_contact(contact, contact_payload)
    attrs = contact_attributes(contact_payload)
    updates = {}
    updates[:name] = attrs[:name] if contact.name.blank? && attrs[:name].present?
    updates[:email] = attrs[:email] if contact_email_available?(contact, attrs[:email])
    updates[:phone_number] = attrs[:phone_number] if contact_phone_number_available?(contact, attrs[:phone_number])
    updates[:identifier] = attrs[:identifier] if contact.identifier.blank? && attrs[:identifier].present?
    updates[:last_activity_at] = attrs[:last_activity_at] if contact.last_activity_at.blank? && attrs[:last_activity_at].present?
    updates[:additional_attributes] = contact.additional_attributes.to_h.deep_merge(attrs[:additional_attributes])
    updates[:custom_attributes] = contact.custom_attributes.to_h.deep_merge(attrs[:custom_attributes])
    if contact.visitor? && attrs[:contact_type].present? && contact_resolved_after_update?(contact, updates)
      updates[:contact_type] = attrs[:contact_type]
    end
    updates[:updated_at] = Time.current
    contact.update_columns(updates) if updates.present?
    contact.reload
  end

  def contact_email_available?(contact, email)
    return false if contact.email.present? || email.blank?

    @account.contacts.where.not(id: contact.id).where('LOWER(email) = ?', email.downcase).empty?
  end

  def contact_phone_number_available?(contact, phone_number)
    return false if contact.phone_number.present? || phone_number.blank?

    @account.contacts.where.not(id: contact.id).where(phone_number: phone_number).empty?
  end

  def contact_resolved_after_update?(contact, updates)
    contact.email.present? || contact.phone_number.present? || updates[:email].present? || updates[:phone_number].present?
  end

  def find_existing_contact(contact_payload)
    identifier = normalized_identifier(contact_payload)
    email = normalized_email(contact_payload)
    phone_number = normalized_phone(contact_payload)

    if identifier.present?
      contact = @account.contacts.find_by(identifier: identifier)
      return contact if contact.present?
    end

    if email.present?
      contact = @account.contacts.from_email(email)
      return contact if contact.present?
    end
    return @account.contacts.find_by(phone_number: phone_number) if phone_number.present?

    nil
  end

  def contact_attributes(contact_payload)
    attrs = {
      account_id: @account.id,
      name: contact_payload['name'].presence || contact_payload['email'].presence || '',
      email: normalized_email(contact_payload),
      phone_number: normalized_phone(contact_payload),
      identifier: normalized_identifier(contact_payload),
      last_activity_at: contact_activity_at(contact_payload),
      additional_attributes: {
        source: {
          provider: PROVIDER,
          contact_id: contact_payload['id'],
          external_id: contact_payload['external_id'],
          raw_phone: contact_payload['phone']
        }.compact
      },
      custom_attributes: {
        intercom_contact_id: contact_payload['id'],
        intercom_external_id: contact_payload['external_id']
      }.compact
    }
    attrs[:contact_type] = Contact.contact_types[:lead] if attrs[:email].present? || attrs[:phone_number].present?
    attrs
  end

  def create_conversation(conversation, contact, contact_inbox, inbox, source_type)
    source_id = source_id_for(conversation)
    metadata = conversation_metadata(conversation, inbox, source_type)
    if (existing_conversation = @account.conversations.find_by(identifier: conversation_identifier(conversation)))
      record_mapping('conversation', source_id, existing_conversation, metadata: metadata)
      return existing_conversation
    end

    attrs = {
      account_id: @account.id,
      inbox_id: inbox.id,
      status: Conversation.statuses['resolved'],
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      identifier: conversation_identifier(conversation),
      additional_attributes: metadata,
      custom_attributes: { intercom_conversation_id: source_id },
      created_at: timestamp_for(conversation['created_at']),
      updated_at: timestamp_for(conversation['updated_at']),
      last_activity_at: timestamp_for(conversation['updated_at'])
    }

    Conversation.transaction do
      result = Conversation.insert_all!([attrs], returning: %w[id])
      chatwoot_conversation = Conversation.find(result.rows.first.first)
      record_mapping('conversation', source_id, chatwoot_conversation, metadata: metadata)
      chatwoot_conversation
    end
  rescue ActiveRecord::RecordNotUnique
    @account.conversations.find_by!(identifier: conversation_identifier(conversation)).tap do |chatwoot_conversation|
      record_mapping('conversation', source_id, chatwoot_conversation, metadata: metadata)
    end
  end

  def import_source_message(conversation, chatwoot_conversation, contact)
    source = conversation['source'].to_h
    return unless source_message_importable?(source)

    message_source_id = "conversation:#{source_id_for(conversation)}:source:#{source['id'].presence || 'initial'}"
    source_part = source.merge('part_type' => 'source', 'created_at' => conversation['created_at'])
    if (mapping = find_mapping('message', message_source_id)) && message_mapping_handled?(mapping, source_part)
      if mapping.data_import_id == @data_import.id
        reconcile_current_run_message_mapping(chatwoot_conversation, mapping, source_part)
        return
      end

      skip_existing_message_mapping(chatwoot_conversation, mapping, source_part)
      return
    end

    create_message(chatwoot_conversation, contact, source_part, message_source_id)
  rescue StandardError => e
    fail_message(chatwoot_conversation, message_source_id, source_part, e)
  end

  def import_conversation_parts(conversation, chatwoot_conversation, contact)
    parts_payload = conversation['conversation_parts'].to_h
    parts = Array(parts_payload['conversation_parts'])
    record_truncated_conversation_parts(conversation, parts.size)

    parts.each do |part|
      message_source_id = "conversation:#{source_id_for(conversation)}:part:#{part['id']}"
      if (mapping = find_mapping('message', message_source_id)) && message_mapping_handled?(mapping, part)
        if mapping.data_import_id == @data_import.id
          reconcile_current_run_message_mapping(chatwoot_conversation, mapping, part)
          next
        end

        skip_existing_message_mapping(chatwoot_conversation, mapping, part)
        next
      end

      create_message(chatwoot_conversation, contact, part, message_source_id)
    rescue StandardError => e
      fail_message(chatwoot_conversation, message_source_id, part, e)
    end
  end

  def create_message(conversation, contact, part, message_source_id)
    content = content_for(part)
    return record_skipped_message(conversation, message_source_id, part) if content.blank?

    attrs = message_attributes(conversation, contact, part, message_source_id, content)
    message = nil
    Message.transaction do
      message = conversation.messages.find_by(source_id: attrs[:source_id])
      unless message
        result = Message.insert_all!([attrs], returning: %w[id])
        message = Message.find(result.rows.first.first)
      end
      record_mapping('message', message_source_id, message, metadata: message_metadata(part))
    end
    increment_stat('messages', 'imported')
    reindex_message_for_search(message)
    message
  end

  def reindex_message_for_search(message)
    return unless message.should_index?

    message.__send__(:reindex_for_search)
  rescue StandardError => e
    Rails.logger.warn("Intercom import message reindex failed for message #{message.id}: #{e.class} - #{e.message}")
  end

  def record_skipped_message(conversation, message_source_id, part)
    mapping = find_mapping('message', message_source_id)
    if mapping
      already_recorded = skip_log_recorded?('message', message_source_id, SKIPPED_MESSAGE_ERROR_CODE)
      record_skipped_message_log(conversation, message_source_id, part)
      increment_stat('messages', 'skipped') unless already_recorded
      return mapping.chatwoot_record
    end

    DataImportMapping.create!(
      account: @account,
      data_import: @data_import,
      source_provider: PROVIDER,
      source_object_type: 'message',
      source_object_id: message_source_id,
      chatwoot_record_type: 'Conversation',
      chatwoot_record_id: conversation.id,
      metadata: message_metadata(part).merge(skipped: true, reason: 'blank_or_unsupported_intercom_part')
    )
    record_skipped_message_log(conversation, message_source_id, part)
    increment_stat('messages', 'skipped')
  end

  def message_attributes(conversation, contact, part, message_source_id, content)
    message_type = message_type_for(part)
    created_at = timestamp_for(part['created_at'])
    {
      account_id: @account.id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      message_type: Message.message_types[message_type],
      content_type: Message.content_types['text'],
      content: content,
      processed_message_content: content,
      private: message_type != 'activity' && part['part_type'] == 'note',
      status: Message.statuses['sent'],
      sender_type: message_type == 'incoming' ? 'Contact' : nil,
      sender_id: message_type == 'incoming' ? contact.id : nil,
      source_id: "intercom:#{message_source_id}",
      external_source_ids: { intercom: message_source_id },
      content_attributes: {},
      additional_attributes: message_metadata(part),
      created_at: created_at,
      updated_at: part['updated_at'].present? ? timestamp_for(part['updated_at']) : created_at
    }
  end

  def message_type_for(part)
    return 'activity' if activity_part?(part)

    author_type = part.dig('author', 'type').to_s
    return 'incoming' if %w[user contact lead].include?(author_type)

    'outgoing'
  end

  def content_for(part)
    return DataImports::Intercom::ActivityContentBuilder.new(part).perform if activity_part?(part)

    message_content(part)
  end

  def activity_part?(part)
    part_type = part['part_type'].to_s
    part_type.present? && REGULAR_MESSAGE_PART_TYPES.exclude?(part_type)
  end

  def message_content(part)
    body = sanitized_text(part['body'])
    subject = sanitized_text(part['subject'])
    attachments = Array(part['attachments'])
    content = [subject, body].reject(&:blank?).join("\n\n")
    return content if attachments.blank?

    [content.presence, "[Intercom attachment skipped: #{attachments.size}]"].compact.join("\n\n")
  end

  def sanitized_text(value)
    Rails::HTML5::FullSanitizer.new.sanitize(value.to_s).squish
  end

  def update_conversation_activity(conversation)
    latest_message = conversation.messages.reorder(created_at: :desc).first
    return if latest_message.blank?

    conversation.update_columns(last_activity_at: latest_message.created_at, updated_at: Time.current)
  end

  def contact_inbox_for(contact, inbox)
    ContactInbox.find_or_create_by!(contact: contact, inbox: inbox) do |contact_inbox|
      contact_inbox.source_id = "intercom:#{contact.id}"
    end
  end

  def primary_conversation_contact(conversation)
    contacts = conversation.dig('contacts', 'contacts') || []
    contacts.first || conversation.dig('source', 'author') || {}
  end

  def conversation_source_type(conversation, conversation_summary)
    conversation.dig('source', 'type').presence ||
      conversation.dig('first_contact_reply', 'type').presence ||
      conversation_summary.dig('source', 'type').presence ||
      conversation_summary.dig('first_contact_reply', 'type').presence
  end

  def normalized_identifier(contact_payload)
    contact_payload['external_id'].presence
  end

  def normalized_email(contact_payload)
    email = contact_payload['email'].to_s.strip.downcase
    email.match?(Devise.email_regexp) ? email : nil
  end

  def normalized_phone(contact_payload)
    phone = contact_payload['phone'].to_s.strip
    phone = "+#{phone}" if phone.match?(INTERCOM_NUMBER_REGEX)
    phone.match?(E164_REGEX) ? phone : nil
  end

  def contact_activity_at(contact_payload)
    return timestamp_for(contact_payload['last_seen_at']) if contact_payload['last_seen_at'].present?
    return timestamp_for(contact_payload['last_replied_at']) if contact_payload['last_replied_at'].present?

    nil
  end

  def source_id_for(payload)
    payload['id'].presence || payload['external_id'].presence || payload['email'].presence
  end

  def conversation_identifier(conversation)
    "intercom:#{source_id_for(conversation)}"
  end

  def import_item(object_type, source_id, metadata)
    @data_import.items.find_or_initialize_by(
      source_provider: PROVIDER,
      source_object_type: object_type,
      source_object_id: source_id
    ).tap do |item|
      item.status = :processing
      item.attempt_count += 1
      item.metadata = item.metadata.to_h.merge(metadata.to_h)
      item.save!
    end
  end

  def item_handled?(object_type, source_id)
    @data_import.items.where(status: [:imported, :skipped]).exists?(
      source_provider: PROVIDER,
      source_object_type: object_type,
      source_object_id: source_id
    )
  end

  def find_mapping(object_type, source_id)
    DataImportMapping.find_by(
      account: @account,
      source_provider: PROVIDER,
      source_object_type: object_type,
      source_object_id: source_id
    )
  end

  def record_mapping(object_type, source_id, record, metadata: {})
    DataImportMapping.find_or_initialize_by(
      account: @account,
      source_provider: PROVIDER,
      source_object_type: object_type,
      source_object_id: source_id
    ).tap do |mapping|
      mapping.data_import = @data_import
      mapping.chatwoot_record_type = record.class.name
      mapping.chatwoot_record_id = record.id
      mapping.metadata = metadata
      mapping.save!
    end
  end

  def reconcile_current_run_contact(contact_payload, source_id, mapped_contact)
    item = @data_import.items.find_by(
      source_provider: PROVIDER,
      source_object_type: 'contact',
      source_object_id: source_id
    )
    item = import_item('contact', source_id, contact_payload) unless item&.imported?
    item.update!(status: :imported, chatwoot_record_type: 'Contact', chatwoot_record_id: mapped_contact.id)
    reconcile_item_stats('contact')
  end

  def reconcile_item_stats(source_object_type)
    items = @data_import.items.where(source_provider: PROVIDER, source_object_type: source_object_type)
    group = stat_group_for(source_object_type)
    @stats[group]['imported'] = items.imported.count
    @stats[group]['skipped'] = items.skipped.count
    persist_stats
  end

  def reconcile_current_run_message_mapping(conversation, mapping, part)
    record_skipped_message_log(conversation, mapping.source_object_id, part) if mapping.metadata['skipped']

    mappings = @data_import.mappings.where(source_provider: PROVIDER, source_object_type: 'message')
    skipped_mappings = mappings.where("metadata ->> 'skipped' = ?", 'true').count
    message_logs = @data_import.import_errors.where(source_object_type: 'message')
    @stats['messages']['imported'] = mappings.count - skipped_mappings
    @stats['messages']['skipped'] = message_logs.where("details ->> 'kind' = ?", 'skipped').count
    persist_stats
  end

  def skip_already_imported_item(item, mapping, already_handled:)
    item.update!(
      status: :skipped,
      chatwoot_record_type: mapping.chatwoot_record_type,
      chatwoot_record_id: mapping.chatwoot_record_id,
      last_error_code: ALREADY_IMPORTED_ERROR_CODE,
      last_error_message: 'Already imported in a previous import.'
    )
    record_already_imported_log(
      data_import_item: item,
      source_object_type: item.source_object_type,
      source_object_id: item.source_object_id,
      mapping: mapping
    )
    increment_stat(stat_group_for(item.source_object_type), 'skipped') unless already_handled
  end

  def skip_existing_message_mapping(conversation, mapping, part)
    if mapping.metadata['skipped']
      already_recorded = skip_log_recorded?('message', mapping.source_object_id, SKIPPED_MESSAGE_ERROR_CODE)
      record_skipped_message_log(conversation, mapping.source_object_id, part)
    else
      already_recorded = skip_log_recorded?('message', mapping.source_object_id, ALREADY_IMPORTED_ERROR_CODE)
      record_already_imported_log(source_object_type: 'message', source_object_id: mapping.source_object_id, mapping: mapping)
    end
    increment_stat('messages', 'skipped') unless already_recorded
  end

  def message_mapping_handled?(mapping, part)
    return false if mapping.metadata['skipped'] && activity_part?(part)

    mapping.metadata['skipped'] || mapping.chatwoot_record.present?
  end

  def fail_item(item, error)
    increment_stat('errors', 'count')
    item&.update!(status: :failed, last_error_code: error.class.name, last_error_message: error.message)
    record_skip_log(
      data_import_item: item,
      source_object_type: item&.source_object_type,
      source_object_id: item&.source_object_id,
      error_code: error.class.name,
      message: error.message,
      details: {
        kind: 'failed',
        source_provider: PROVIDER,
        error_class: error.class.name
      }
    )
  end

  def fail_message(conversation, message_source_id, part, error)
    increment_stat('errors', 'count')
    record_skip_log(
      source_object_type: 'message',
      source_object_id: message_source_id,
      error_code: error.class.name,
      message: error.message,
      details: message_metadata(part).merge(
        kind: 'failed',
        source_provider: PROVIDER,
        error_class: error.class.name,
        conversation_id: conversation.identifier
      )
    )
  end

  def record_skipped_message_log(conversation, message_source_id, part)
    record_skip_log(
      source_object_type: 'message',
      source_object_id: message_source_id,
      error_code: SKIPPED_MESSAGE_ERROR_CODE,
      message: skipped_message_log_message(part),
      details: skipped_message_details(conversation, part)
    )
  end

  def record_already_imported_log(source_object_type:, source_object_id:, mapping:, data_import_item: nil)
    record_skip_log(
      data_import_item: data_import_item,
      source_object_type: source_object_type,
      source_object_id: source_object_id,
      error_code: ALREADY_IMPORTED_ERROR_CODE,
      message: 'Already imported in a previous import.',
      details: {
        kind: 'skipped',
        reason: 'already_imported',
        source_provider: PROVIDER,
        previous_data_import_id: mapping.data_import_id,
        chatwoot_record_type: mapping.chatwoot_record_type,
        chatwoot_record_id: mapping.chatwoot_record_id
      }
    )
  end

  def record_truncated_conversation_parts(conversation, imported_parts_count)
    total_parts_count = total_conversation_parts_count(conversation)
    return if total_parts_count <= imported_parts_count

    source_id = source_id_for(conversation)
    already_recorded = @data_import.import_errors.exists?(
      source_object_type: 'conversation',
      source_object_id: source_id,
      error_code: TRUNCATED_PARTS_ERROR_CODE
    )
    record_import_error(
      source_object_type: 'conversation',
      source_object_id: source_id,
      error_code: TRUNCATED_PARTS_ERROR_CODE,
      message: "Intercom returned #{imported_parts_count} of #{total_parts_count} conversation parts.",
      details: {
        kind: 'incomplete',
        source_provider: PROVIDER,
        imported_parts_count: imported_parts_count,
        total_parts_count: total_parts_count
      }
    )
    increment_stat('errors', 'count') unless already_recorded
  end

  def total_conversation_parts_count(conversation)
    conversation_parts_total_count = conversation.dig('conversation_parts', 'total_count')
    return conversation_parts_total_count.to_i if conversation_parts_total_count.present?

    [
      conversation.dig('statistics', 'count_conversation_parts'),
      conversation.dig('statistics', 'count_conversations_parts')
    ].compact.map(&:to_i).max || 0
  end

  def source_message_importable?(source)
    source['body'].present? || source['subject'].present? || source['attachments'].present?
  end

  def skipped_message_log_message(part)
    "Skipped Intercom #{intercom_event_name(part)} event#{intercom_part_id_suffix(part)}: #{skipped_message_reason_details(part)}."
  end

  def skipped_message_details(conversation, part)
    author = part['author'].to_h
    message_metadata(part).merge(
      {
        kind: 'skipped',
        reason: 'blank_or_unsupported_intercom_part',
        reason_details: skipped_message_reason_details(part),
        event_name: intercom_event_name(part),
        event_type: part['part_type'],
        author_type: author['type'],
        author_name: author['name'],
        conversation_id: conversation.identifier
      }.compact
    )
  end

  def skipped_message_reason_details(part)
    return 'message body did not contain readable text after HTML sanitization' if part['body'].present?
    return 'attachments are present but no importable message text was found' if Array(part['attachments']).present?

    'no message body or attachments to import'
  end

  def intercom_event_name(part)
    part['part_type'].to_s.tr('_', ' ').presence || 'message part'
  end

  def intercom_part_id_suffix(part)
    part['id'].present? ? " #{part['id']}" : ''
  end

  def skip_log_recorded?(source_object_type, source_object_id, error_code)
    @data_import.import_errors.skip_logs.exists?(
      source_object_type: source_object_type,
      source_object_id: source_object_id,
      error_code: error_code
    )
  end

  def record_run_error(error)
    @data_import.import_errors.create!(
      error_code: error.class.name,
      message: error.message,
      details: {
        kind: 'run_error',
        source_provider: PROVIDER,
        error_class: error.class.name
      }
    )
  end

  def record_skip_log(attributes)
    record_import_error(attributes)
  end

  def record_import_error(attributes)
    @data_import.import_errors.find_or_initialize_by(
      data_import_item: attributes[:data_import_item],
      source_object_type: attributes[:source_object_type],
      source_object_id: attributes[:source_object_id],
      error_code: attributes[:error_code]
    ).tap do |import_error|
      import_error.message = attributes[:message]
      import_error.details = attributes[:details]
      import_error.save!
    end
  end

  def conversation_metadata(conversation, inbox, source_type)
    {
      source: {
        provider: PROVIDER,
        conversation_id: source_id_for(conversation),
        source_type: source_type,
        delivered_as: conversation.dig('source', 'delivered_as'),
        source_url: conversation.dig('source', 'url'),
        admin_assignee_id: conversation['admin_assignee_id'],
        team_assignee_id: conversation['team_assignee_id'],
        state: conversation['state'],
        open: conversation['open'],
        routing_method: 'source_bucket_api_inbox',
        routed_inbox_id: inbox.id,
        import_id: @data_import.id
      }.compact
    }
  end

  def contact_metadata(contact_payload)
    {
      source: {
        provider: PROVIDER,
        contact_id: contact_payload['id'],
        external_id: contact_payload['external_id']
      }.compact
    }
  end

  def message_metadata(part)
    {
      source: {
        provider: PROVIDER,
        part_id: part['id'],
        part_type: part['part_type'],
        author: part['author'],
        assigned_to: part['assigned_to'],
        state: part['state'],
        tags: part['tags'],
        event_details: part['event_details'],
        app_package_code: part['app_package_code'],
        metadata: part['metadata'],
        attachments: part['attachments'],
        redacted: part['redacted']
      }.compact
    }
  end

  def timestamp_for(value)
    return Time.current if value.blank?

    Time.zone.at(value.to_i)
  end

  def update_cursor(key, cursor)
    @data_import.cursor = @data_import.cursor.to_h.merge(
      key => { starting_after: cursor, completed: cursor.blank?, updated_at: Time.current.iso8601 }
    )
    @data_import.save!
  end

  def stage_completed?(key)
    @data_import.cursor&.dig(key, 'completed') == true
  end

  def import_type?(type)
    import_types.include?(type)
  end

  def import_types
    @import_types ||= (@data_import.import_types.presence || DEFAULT_IMPORT_TYPES)
  end

  def increment_stat(group, key)
    @stats[group] ||= {}
    @stats[group][key] = @stats[group][key].to_i + 1
  end

  def update_stat_total(group, total)
    @stats[group] ||= {}
    @stats[group]['total'] = total.to_i
    persist_stats
  end

  def update_message_total(item, conversation)
    parts = conversation['conversation_parts'].to_h
    conversation_parts_total = if parts.key?('total_count')
                                 parts['total_count'].to_i
                               else
                                 Array(parts['conversation_parts']).size
                               end
    contribution = conversation_parts_total
    contribution += 1 if source_message_importable?(conversation['source'].to_h)
    previous_contribution = item.metadata.to_h['message_total_contribution'].to_i

    @stats['messages']['total'] = @stats['messages']['total'].to_i + contribution - previous_contribution
    item.update!(metadata: item.metadata.to_h.merge('message_total_contribution' => contribution))
    persist_stats
  end

  def stat_group_for(source_object_type)
    "#{source_object_type}s"
  end

  def persist_stats
    @data_import.update_columns(stats: @stats, updated_at: Time.current)
  end

  def default_stats
    {
      'contacts' => { 'imported' => 0, 'skipped' => 0 },
      'conversations' => { 'imported' => 0, 'skipped' => 0 },
      'messages' => { 'imported' => 0, 'skipped' => 0 },
      'errors' => { 'count' => 0 }
    }
  end

  def total_processed_records
    total_successful_records +
      @stats.fetch('contacts', {}).fetch('skipped', 0).to_i +
      @stats.fetch('conversations', {}).fetch('skipped', 0).to_i +
      @stats.fetch('messages', {}).fetch('skipped', 0).to_i +
      @stats.fetch('errors', {}).fetch('count', 0).to_i
  end

  def total_successful_records
    @stats.fetch('contacts', {}).fetch('imported', 0).to_i +
      @stats.fetch('conversations', {}).fetch('imported', 0).to_i +
      @stats.fetch('messages', {}).fetch('imported', 0).to_i
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Rails/SkipsModelValidations
