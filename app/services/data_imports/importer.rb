# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Rails/SkipsModelValidations
class DataImports::Importer
  class InvalidMessagePayloadError < StandardError; end

  PageResult = Struct.new(:next_cursor, keyword_init: true) do
    def done?
      next_cursor.blank?
    end
  end

  DEFAULT_IMPORT_TYPES = %w[contacts conversations].freeze
  MESSAGES_PER_BATCH = 100
  HEARTBEAT_INTERVAL = 1.minute
  QUERY_TIMEOUT_RETRY_LIMIT = 1
  QUERY_TIMEOUT_RETRY_DELAY_RANGE = (0.2..0.5)
  MESSAGE_MAPPING_UNIQUE_INDEX = :idx_data_import_mappings_on_account_and_source
  E164_REGEX = /\A\+[1-9]\d{1,14}\z/
  PHONE_WITHOUT_PLUS_REGEX = /\A[1-9]\d{1,14}\z/

  MessageBatchResult = Struct.new(
    :imported_entries,
    :skipped_entries,
    :current_entries,
    :previous_entries,
    :messages,
    :failed_entries,
    keyword_init: true
  )

  def initialize(data_import:, run_id: nil, source: nil)
    @data_import = data_import
    @run_id = run_id
    @account = data_import.account
    @source = source || DataImports::Source.for(data_import)
    @placeholder_inboxes = @source.placeholder_inbox_builder(account: @account)
    @stats = default_stats.deep_merge(data_import.stats || {})
    @persisted_cursor = data_import.cursor.to_h.deep_stringify_keys
    @persisted_stats = @stats.deep_dup
    @dirty_stat_groups = {}
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
    @data_import.with_lock do
      next if @data_import.abandoned? || stale_import_run?

      error_count = @data_import.import_errors.non_skip_logs.count + @data_import.import_errors.failed.count
      @stats['errors']['count'] = error_count
      status = error_count.positive? ? :completed_with_errors : :completed
      @data_import.update!(
        status: status,
        completed_at: Time.current,
        stats: @stats,
        total_records: total_processed_records,
        processed_records: total_successful_records
      )
    end
  end

  def fail!(error)
    @data_import.with_lock do
      next if @data_import.abandoned? || stale_import_run?

      record_run_error(error)
      @data_import.update!(status: :failed, last_error_at: Time.current)
    end
  end

  def import_contacts_page(starting_after: cursor_for('contacts'))
    response = @source.list_contacts(starting_after: starting_after, per_page: @source.contacts_per_page)
    update_stat_total('contacts', response['total_count']) if response['total_count'].present?
    Array(response['data'] || response['contacts']).each do |contact|
      break if import_stopped?

      import_contact(contact)
    end
    return PageResult.new(next_cursor: nil) if import_stopped?

    reconcile_dirty_stats
    next_cursor = response.dig('pages', 'next', 'starting_after')
    next_cursor = update_cursor('contacts', next_cursor)
    PageResult.new(next_cursor: next_cursor)
  end

  def import_conversations_page(starting_after: cursor_for('conversations'))
    response = @source.list_conversations(starting_after: starting_after, per_page: @source.conversations_per_page)
    update_stat_total('conversations', response['total_count']) if response['total_count'].present?
    Array(response['data'] || response['conversations']).each do |conversation_summary|
      break if import_stopped?

      import_conversation_from_summary(conversation_summary)
    end
    return PageResult.new(next_cursor: nil) if import_stopped?

    reconcile_dirty_stats
    next_cursor = response.dig('pages', 'next', 'starting_after')
    next_cursor = update_cursor('conversations', next_cursor)
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
    item, already_handled = prepare_import_item('conversation', source_id, conversation_summary)
    conversation = @source.retrieve_conversation(source_id)
    return if import_stopped?

    with_import_item_lock(item, already_handled: already_handled) do |locked_item, item_already_handled|
      import_conversation_item(locked_item, conversation_summary, conversation, source_id, item_already_handled)
    end
  rescue StandardError => e
    raise if @source.client_error?(e)

    fail_item(item, e)
  ensure
    persist_stats unless @import_stopped
  end

  def import_conversation_item(item, conversation_summary, conversation, source_id, already_handled)
    mapping = find_mapping('conversation', source_id)
    update_message_total(item, conversation)

    contact_payloads = conversation_contacts(conversation)
    contact = import_contact(contact_payloads.first, required_for_conversation: true)
    contact_payloads.drop(1).each { |contact_payload| import_contact(contact_payload) }
    source_type = conversation_source_type(conversation, conversation_summary)
    inbox = @placeholder_inboxes.inbox_for(source_type)
    contact_inbox = contact_inbox_for(contact, inbox)

    mapped_conversation = mapping&.chatwoot_record
    if mapped_conversation && mapping.data_import_id != @data_import.id
      skip_already_imported_item(item, mapping, already_handled: already_handled)
      reconcile_item_stats('conversation') if already_handled
      return unless import_conversation_messages(conversation, mapped_conversation, contact)

      update_conversation_activity(mapped_conversation)
      return
    end

    chatwoot_conversation = mapped_conversation || create_conversation(conversation, contact, contact_inbox, inbox, source_type)
    if mapped_conversation
      record_mapping('conversation', source_id, chatwoot_conversation, metadata: conversation_metadata(conversation, inbox, source_type))
    end
    item.update!(status: :imported, chatwoot_record_type: 'Conversation', chatwoot_record_id: chatwoot_conversation.id)
    if already_handled
      reconcile_item_stats('conversation')
    else
      increment_stat('conversations', 'imported')
    end

    return unless import_conversation_messages(conversation, chatwoot_conversation, contact)

    update_conversation_activity(chatwoot_conversation)
  end

  def import_stopped?
    return true if @import_stopped

    @data_import.reload
    @import_stopped = @data_import.abandoned? || @data_import.completed? || @data_import.completed_with_errors? || stale_import_run?
  end

  def continue_import_with_heartbeat?
    return false if import_stopped?
    return true if @data_import.updated_at > HEARTBEAT_INTERVAL.ago

    @data_import.touch if @data_import.updated_at <= HEARTBEAT_INTERVAL.ago
    true
  end

  def stale_import_run?
    active_run_id = @data_import.active_import_run_id
    @run_id.present? && active_run_id.present? && active_run_id != @run_id
  end

  def import_contact(contact_payload, required_for_conversation: false)
    item = nil
    with_query_timeout_retry do
      source_id = source_id_for(contact_payload)
      mapping = find_mapping('contact', source_id) if source_id.present?
      contact_payload = retrieve_contact_payload(contact_payload) unless mapping&.chatwoot_record
      source_id = source_id_for(contact_payload)
      item, already_handled = prepare_import_item('contact', source_id, contact_payload)

      with_import_item_lock(item, already_handled: already_handled) do |locked_item, item_already_handled|
        import_contact_item(locked_item, contact_payload, source_id, item_already_handled)
      end
    end
  rescue StandardError => e
    raise if @source.client_error?(e)

    fail_item(item, e)
    raise if required_for_conversation
  ensure
    persist_stats
  end

  def import_contact_item(item, contact_payload, source_id, already_handled)
    mapping = find_mapping('contact', source_id)
    mapped_contact = mapping&.chatwoot_record
    return reuse_mapped_contact(item, mapping, mapped_contact, already_handled: already_handled) if mapped_contact

    contact = Contact.transaction do
      imported_contact = find_existing_contact(contact_payload) || create_contact(contact_payload)
      update_existing_contact(imported_contact, contact_payload)
      record_mapping('contact', source_id, imported_contact, metadata: contact_metadata(contact_payload))
      item.update!(status: :imported, chatwoot_record_type: 'Contact', chatwoot_record_id: imported_contact.id)
      imported_contact
    end
    increment_stat('contacts', 'imported') unless already_handled
    contact
  end

  def retrieve_contact_payload(contact_payload)
    return contact_payload if contact_payload.blank?
    return contact_payload if contact_payload['email'].present? || contact_payload['phone'].present? || contact_payload['name'].present?
    return contact_payload if contact_payload['id'].blank?

    @source.retrieve_contact(contact_payload['id'])
  rescue StandardError => e
    raise unless @source.client_error?(e)
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

  def reuse_mapped_contact(item, mapping, mapped_contact, already_handled:)
    if mapping.data_import_id == @data_import.id
      reconcile_current_run_contact(item, mapped_contact)
      return mapped_contact
    end

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
        source: @source.contact_source_metadata(contact_payload).merge(provider: @source.provider)
      },
      custom_attributes: @source.contact_custom_attributes(contact_payload)
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
      custom_attributes: @source.conversation_custom_attributes(conversation),
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

  def import_conversation_messages(conversation, chatwoot_conversation, contact)
    parts_payload = conversation['conversation_parts'].to_h
    parts = Array(parts_payload['conversation_parts'])
    batch_builder = @source.message_batch_builder(
      data_import: @data_import,
      conversation: chatwoot_conversation,
      source_conversation: conversation
    )
    batch = begin
      with_query_timeout_retry { batch_builder.perform }
    rescue ActiveRecord::QueryCanceled
      nil
    end
    return import_conversation_messages_individually(conversation, chatwoot_conversation, contact, batch_builder, parts.size) if batch.nil?

    record_truncated_conversation_parts(conversation, parts.size)

    batch.entries.each_slice(MESSAGES_PER_BATCH) do |entries|
      return false unless continue_import_with_heartbeat?

      import_message_batch(chatwoot_conversation, contact, batch_builder, entries)
      return false if @import_stopped
    end
    return false if import_stopped?

    true
  end

  def import_message_batch(conversation, contact, batch_builder, entries)
    result = bulk_message_batch_result(conversation, contact, batch_builder, entries)
    return if result.blank?

    result.current_entries.each do |entry|
      reconcile_bulk_message_entry(conversation, entry) do
        reconcile_current_run_message_mapping(conversation, entry.mapping, entry.part)
      end
    end
    result.previous_entries.each do |entry|
      reconcile_bulk_message_entry(conversation, entry) do
        skip_existing_message_mapping(conversation, entry.mapping, entry.part)
      end
    end
    result.skipped_entries.each do |entry|
      reconcile_bulk_message_entry(conversation, entry) { record_bulk_skipped_message(conversation, entry) }
    end
    Array(result.failed_entries).each { |entry, error| fail_message(conversation, entry.source_id, entry.part, error) }
    increment_stat('messages', 'imported', result.imported_entries.size)
    result.messages.each { |message| reindex_message_for_search(message) }
  end

  def bulk_message_batch_result(conversation, contact, batch_builder, entries)
    with_query_timeout_retry do
      bulk_write_message_entries(conversation, contact, batch_builder, entries)
    end
  rescue ActiveRecord::ActiveRecordError
    fallback_message_entries(conversation, contact, batch_builder, entries) unless @import_stopped
    nil
  end

  def fallback_message_entries(conversation, contact, batch_builder, entries)
    entries.each do |entry|
      break unless continue_import_with_heartbeat?

      message = fallback_message_entry(conversation, contact, batch_builder, entry)
      reindex_message_for_search(message) if message.is_a?(Message)
    end
  end

  def fallback_message_entry(conversation, contact, batch_builder, entry)
    with_query_timeout_retry do
      @data_import.with_lock do
        if inactive_import_run?
          @import_stopped = true
          next
        end

        refreshed_entry = batch_builder.refresh([entry]).entries.first
        import_message(conversation, contact, refreshed_entry, reindex: false)
      end
    end
  rescue ActiveRecord::ActiveRecordError => e
    fail_message(conversation, entry.source_id, entry.part, e)
  end

  def bulk_write_message_entries(conversation, contact, batch_builder, entries)
    @data_import.with_lock do
      if inactive_import_run?
        @import_stopped = true
        next
      end

      refreshed_entries = batch_builder.refresh(entries).entries
      persist_message_entries(conversation, contact, refreshed_entries)
    end
  end

  def inactive_import_run?
    @data_import.abandoned? || @data_import.failed? || @data_import.completed? ||
      @data_import.completed_with_errors? || stale_import_run?
  end

  def persist_message_entries(conversation, contact, entries)
    grouped_entries = entries.group_by(&:classification)
    writable_entries = entries.select do |entry|
      %i[repairable_stale_mapping existing_message new_message].include?(entry.classification)
    end
    content_by_source_id = {}
    attributes_by_source_id = {}
    failed_entries = []
    writable_entries.select! do |entry|
      validate_message_payload!(entry.part)
      content = content_for(entry.part)
      content_by_source_id[entry.source_id] = content
      if content.present? && entry.message.blank?
        attributes_by_source_id[entry.source_id] = message_attributes(conversation, contact, entry.part, entry.source_id, content)
      end
      true
    rescue InvalidMessagePayloadError => e
      failed_entries << [entry, e]
      false
    end
    skipped_entries, imported_entries = writable_entries.partition { |entry| content_by_source_id[entry.source_id].blank? }
    messages = insert_messages(imported_entries, attributes_by_source_id)
    upsert_message_mappings(conversation, imported_entries, skipped_entries, messages)

    MessageBatchResult.new(
      imported_entries: imported_entries,
      skipped_entries: skipped_entries,
      current_entries: grouped_entries.fetch(:current_import, []),
      previous_entries: grouped_entries.fetch(:previous_import, []),
      messages: messages,
      failed_entries: failed_entries
    )
  end

  def insert_messages(entries, attributes_by_source_id)
    new_entries = entries.reject(&:message)
    if new_entries.present?
      attributes = new_entries.map { |entry| attributes_by_source_id.fetch(entry.source_id) }
      result = Message.insert_all!(attributes, returning: %w[id source_id])
      inserted_messages = Message.where(id: result.pluck('id')).index_by(&:source_id)
    end

    entries.map do |entry|
      entry.message || inserted_messages.fetch("#{@source.provider}:#{entry.source_id}")
    end
  end

  def validate_message_payload!(part)
    raise InvalidMessagePayloadError, "#{@source.display_name} message payload must be an object" unless part.is_a?(Hash)

    %w[author assigned_to event_details].each do |field|
      value = part[field]
      next if value.nil? || value.is_a?(Hash)

      raise InvalidMessagePayloadError, "#{@source.display_name} message #{field} must be an object"
    end

    participant = part.dig('event_details', 'participant')
    unless participant.nil? || participant.is_a?(Hash)
      raise InvalidMessagePayloadError, "#{@source.display_name} message event_details.participant must be an object"
    end

    %w[created_at updated_at].each do |field|
      value = part[field]
      valid_timestamp = value.nil? || value.is_a?(Integer) || value.is_a?(Float) ||
                        (value.is_a?(String) && (value.blank? || value.match?(/\A-?\d+(?:\.\d+)?\z/)))
      raise InvalidMessagePayloadError, "#{@source.display_name} message #{field} must be a Unix timestamp" unless valid_timestamp

      timestamp_for(value) if value.present?
    rescue RangeError
      raise InvalidMessagePayloadError, "#{@source.display_name} message #{field} must be a Unix timestamp"
    end

    %w[body subject].each do |field|
      value = part[field]
      next unless value.is_a?(String) && !value.valid_encoding?

      raise InvalidMessagePayloadError, "#{@source.display_name} message #{field} must use valid encoding"
    end
  end

  def upsert_message_mappings(conversation, imported_entries, skipped_entries, messages)
    now = Time.current
    mapping_attributes = imported_entries.zip(messages).map do |entry, message|
      message_mapping_attributes(entry, 'Message', message.id, message_metadata(entry.part), now)
    end
    mapping_attributes.concat(skipped_entries.filter_map do |entry|
      next if entry.mapping

      metadata = message_metadata(entry.part).merge(skipped: true, reason: @source.skipped_message_reason)
      message_mapping_attributes(entry, 'Conversation', conversation.id, metadata, now)
    end)
    return if mapping_attributes.empty?

    DataImportMapping.upsert_all(
      mapping_attributes,
      unique_by: MESSAGE_MAPPING_UNIQUE_INDEX,
      update_only: %i[data_import_id chatwoot_record_type chatwoot_record_id metadata updated_at],
      record_timestamps: false
    )
  end

  def message_mapping_attributes(entry, record_type, record_id, metadata, now)
    {
      account_id: @account.id,
      data_import_id: @data_import.id,
      source_provider: @source.provider,
      source_object_type: 'message',
      source_object_id: entry.source_id,
      chatwoot_record_type: record_type,
      chatwoot_record_id: record_id,
      metadata: metadata,
      created_at: entry.mapping&.created_at || now,
      updated_at: now
    }
  end

  def record_bulk_skipped_message(conversation, entry)
    already_recorded = skip_log_recorded?('message', entry.source_id, @source.skipped_message_error_code)
    record_skipped_message_log(conversation, entry.source_id, entry.part)
    increment_stat('messages', 'skipped') unless already_recorded
  end

  def reconcile_bulk_message_entry(conversation, entry, &)
    with_query_timeout_retry(&)
  rescue StandardError => e
    fail_message(conversation, entry.source_id, entry.part, e)
  end

  def import_conversation_messages_individually(conversation, chatwoot_conversation, contact, batch_builder, parts_count)
    source_entries, part_entries = batch_builder.unprepared_entries.partition { |entry| entry[:part]['part_type'] == 'source' }
    source_entries.each { |entry| import_unprepared_message(chatwoot_conversation, contact, batch_builder, entry) }
    record_truncated_conversation_parts(conversation, parts_count)

    part_entries.each do |entry|
      return false unless continue_import_with_heartbeat?

      import_unprepared_message(chatwoot_conversation, contact, batch_builder, entry)
    end
    return false if import_stopped?

    true
  end

  def import_unprepared_message(conversation, contact, batch_builder, source_entry)
    with_query_timeout_retry do
      @data_import.with_lock do
        if inactive_import_run?
          @import_stopped = true
          next
        end

        entry = batch_builder.perform([source_entry]).entries.first
        import_message(conversation, contact, entry)
      end
    end
  rescue StandardError => e
    fail_message(conversation, source_entry[:source_id], source_entry[:part], e)
  end

  def import_message(conversation, contact, entry, reindex: true)
    message = with_query_timeout_retry do
      Message.transaction(requires_new: true) do
        case entry.classification
        when :current_import
          reconcile_current_run_message_mapping(conversation, entry.mapping, entry.part)
        when :previous_import
          skip_existing_message_mapping(conversation, entry.mapping, entry.part)
        when :repairable_stale_mapping, :existing_message, :new_message
          create_message(conversation, contact, entry)
        else
          raise ArgumentError, "Unsupported #{@source.display_name} message classification: #{entry.classification}"
        end
      end
    end
    reindex_message_for_search(message) if reindex && message.is_a?(Message)
    message
  rescue StandardError => e
    fail_message(conversation, entry.source_id, entry.part, e)
  end

  def create_message(conversation, contact, entry)
    validate_message_payload!(entry.part)
    content = content_for(entry.part)
    return record_skipped_message(conversation, entry) if content.blank?

    attrs = message_attributes(conversation, contact, entry.part, entry.source_id, content)
    message = entry.message
    unless message
      result = Message.insert_all!([attrs], returning: %w[id])
      message = Message.find(result.rows.first.first)
    end
    record_message_mapping(entry, message)
    increment_stat('messages', 'imported')
    message
  end

  def reindex_message_for_search(message)
    return unless message.should_index?

    message.__send__(:reindex_for_search)
  rescue StandardError => e
    Rails.logger.warn("#{@source.display_name} import message reindex failed for message #{message.id}: #{e.class} - #{e.message}")
  end

  def record_skipped_message(conversation, entry)
    if entry.mapping
      already_recorded = skip_log_recorded?('message', entry.source_id, @source.skipped_message_error_code)
      record_skipped_message_log(conversation, entry.source_id, entry.part)
      increment_stat('messages', 'skipped') unless already_recorded
      return entry.message
    end

    DataImportMapping.create!(
      account: @account,
      data_import: @data_import,
      source_provider: @source.provider,
      source_object_type: 'message',
      source_object_id: entry.source_id,
      chatwoot_record_type: 'Conversation',
      chatwoot_record_id: conversation.id,
      metadata: message_metadata(entry.part).merge(skipped: true, reason: @source.skipped_message_reason)
    )
    record_skipped_message_log(conversation, entry.source_id, entry.part)
    increment_stat('messages', 'skipped')
  end

  def record_message_mapping(entry, message)
    (entry.mapping || DataImportMapping.new(
      account: @account,
      source_provider: @source.provider,
      source_object_type: 'message',
      source_object_id: entry.source_id
    )).tap do |mapping|
      mapping.data_import = @data_import
      mapping.chatwoot_record_type = 'Message'
      mapping.chatwoot_record_id = message.id
      mapping.metadata = message_metadata(entry.part)
      mapping.save!
    end
  end

  def message_attributes(conversation, contact, part, message_source_id, content)
    message_type = message_type_for(part)
    sender = message_sender_for(part, contact, message_type)
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
      sender_type: sender.present? ? 'Contact' : nil,
      sender_id: sender&.id,
      source_id: "#{@source.provider}:#{message_source_id}",
      external_source_ids: { @source.provider => message_source_id },
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
    return @source.activity_content(part) if activity_part?(part)

    message_content(part)
  end

  def activity_part?(part)
    @source.activity_part?(part)
  end

  def message_content(part)
    body = sanitized_text(part['body'])
    subject = sanitized_text(part['subject'])
    attachments = Array(part['attachments'])
    content = [subject, body].reject(&:blank?).join("\n\n")
    return content if attachments.blank?

    [content.presence, "[#{@source.display_name} attachment skipped: #{attachments.size}]"].compact.join("\n\n")
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
      contact_inbox.source_id = "#{@source.provider}:#{contact.id}"
    end
  end

  def conversation_contacts(conversation)
    contacts = Array(conversation.dig('contacts', 'contacts'))
    contacts.presence || [conversation.dig('source', 'author') || {}]
  end

  def message_sender_for(part, primary_contact, message_type)
    return unless message_type == 'incoming'

    author = part['author'].to_h
    source_id = source_id_for(author)
    mapped_contact = find_mapping('contact', source_id)&.chatwoot_record if source_id.present?
    mapped_contact || find_existing_contact(author) || primary_contact
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
    phone = "+#{phone}" if phone.match?(PHONE_WITHOUT_PLUS_REGEX)
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
    "#{@source.provider}:#{source_id_for(conversation)}"
  end

  def find_or_create_import_item(object_type, source_id)
    attributes = {
      source_provider: @source.provider,
      source_object_type: object_type,
      source_object_id: source_id
    }
    @data_import.items.find_by(attributes) || @data_import.items.create!(attributes)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    @data_import.items.find_by(attributes) || raise(e)
  end

  def prepare_import_item(object_type, source_id, metadata)
    item = find_or_create_import_item(object_type, source_id)
    already_handled = item.with_lock do
      already_handled = item.imported? || item.skipped?
      item.status = :processing
      item.attempt_count += 1
      item.metadata = item.metadata.to_h.merge(metadata.to_h)
      item.save!
      already_handled
    end
    [item, already_handled]
  end

  def with_import_item_lock(item, already_handled:)
    ApplicationRecord.connection_pool.with_connection do |connection|
      lock_id = -item.id
      connection.execute("SELECT pg_advisory_lock(#{lock_id})")
      begin
        item.reload
        yield item, already_handled || item.imported? || item.skipped?
      ensure
        connection.execute("SELECT pg_advisory_unlock(#{lock_id})")
      end
    end
  end

  def find_mapping(object_type, source_id)
    DataImportMapping.find_by(
      account: @account,
      source_provider: @source.provider,
      source_object_type: object_type,
      source_object_id: source_id
    )
  end

  def record_mapping(object_type, source_id, record, metadata: {})
    DataImportMapping.find_or_initialize_by(
      account: @account,
      source_provider: @source.provider,
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

  def reconcile_current_run_contact(item, mapped_contact)
    item.update!(status: :imported, chatwoot_record_type: 'Contact', chatwoot_record_id: mapped_contact.id)
    mark_stat_group_dirty('contacts')
  end

  def reconcile_item_stats(source_object_type)
    items = @data_import.items.where(source_provider: @source.provider, source_object_type: source_object_type)
    group = stat_group_for(source_object_type)
    @stats[group]['imported'] = items.imported.count
    @stats[group]['skipped'] = items.skipped.count
  end

  def reconcile_current_run_message_mapping(conversation, mapping, part)
    record_skipped_message_log(conversation, mapping.source_object_id, part) if mapping.metadata['skipped']
    mark_stat_group_dirty('messages')
  end

  def reconcile_message_stats
    mappings = @data_import.mappings.where(source_provider: @source.provider, source_object_type: 'message')
    skipped_mappings = mappings.where("metadata ->> 'skipped' = ?", 'true').count
    message_logs = @data_import.import_errors.where(source_object_type: 'message')
    @stats['messages']['imported'] = mappings.count - skipped_mappings
    @stats['messages']['skipped'] = message_logs.where("details ->> 'kind' = ?", 'skipped').count
  end

  def skip_already_imported_item(item, mapping, already_handled:)
    DataImportItem.transaction do
      item.update!(
        status: :skipped,
        chatwoot_record_type: mapping.chatwoot_record_type,
        chatwoot_record_id: mapping.chatwoot_record_id,
        last_error_code: @source.already_imported_error_code,
        last_error_message: 'Already imported in a previous import.'
      )
      record_already_imported_log(
        data_import_item: item,
        source_object_type: item.source_object_type,
        source_object_id: item.source_object_id,
        mapping: mapping
      )
    end
    increment_stat(stat_group_for(item.source_object_type), 'skipped') unless already_handled
  end

  def skip_existing_message_mapping(conversation, mapping, part)
    if mapping.metadata['skipped']
      already_recorded = skip_log_recorded?('message', mapping.source_object_id, @source.skipped_message_error_code)
      record_skipped_message_log(conversation, mapping.source_object_id, part)
    else
      already_recorded = skip_log_recorded?('message', mapping.source_object_id, @source.already_imported_error_code)
      record_already_imported_log(source_object_type: 'message', source_object_id: mapping.source_object_id, mapping: mapping)
    end
    if already_recorded
      message_logs = @data_import.import_errors.where(source_object_type: 'message')
      @stats['messages']['skipped'] = message_logs.where("details ->> 'kind' = ?", 'skipped').count
    else
      increment_stat('messages', 'skipped')
    end
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
        source_provider: @source.provider,
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
        source_provider: @source.provider,
        error_class: error.class.name,
        conversation_id: conversation.identifier
      )
    )
  end

  def record_skipped_message_log(conversation, message_source_id, part)
    record_skip_log(
      source_object_type: 'message',
      source_object_id: message_source_id,
      error_code: @source.skipped_message_error_code,
      message: skipped_message_log_message(part),
      details: skipped_message_details(conversation, part)
    )
  end

  def record_already_imported_log(source_object_type:, source_object_id:, mapping:, data_import_item: nil)
    record_skip_log(
      data_import_item: data_import_item,
      source_object_type: source_object_type,
      source_object_id: source_object_id,
      error_code: @source.already_imported_error_code,
      message: 'Already imported in a previous import.',
      details: {
        kind: 'skipped',
        reason: 'already_imported',
        source_provider: @source.provider,
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
      error_code: @source.truncated_parts_error_code
    )
    record_import_error(
      source_object_type: 'conversation',
      source_object_id: source_id,
      error_code: @source.truncated_parts_error_code,
      message: "#{@source.display_name} returned #{imported_parts_count} of #{total_parts_count} conversation parts.",
      details: {
        kind: 'incomplete',
        source_provider: @source.provider,
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
    @source.source_message_importable?(source)
  end

  def skipped_message_log_message(part)
    "Skipped #{@source.display_name} #{source_event_name(part)} event#{source_part_id_suffix(part)}: #{skipped_message_reason_details(part)}."
  end

  def skipped_message_details(conversation, part)
    author = part['author'].to_h
    message_metadata(part).merge(
      {
        kind: 'skipped',
        reason: @source.skipped_message_reason,
        reason_details: skipped_message_reason_details(part),
        event_name: source_event_name(part),
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

  def source_event_name(part)
    part['part_type'].to_s.tr('_', ' ').presence || 'message part'
  end

  def source_part_id_suffix(part)
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
        source_provider: @source.provider,
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
        provider: @source.provider,
        conversation_id: source_id_for(conversation),
        source_type: source_type,
        **@source.conversation_source_metadata(conversation),
        routing_method: 'source_bucket_api_inbox',
        routed_inbox_id: inbox.id,
        import_id: @data_import.id
      }.compact
    }
  end

  def contact_metadata(contact_payload)
    {
      source: {
        provider: @source.provider,
        **@source.contact_source_metadata(contact_payload)
      }.compact
    }
  end

  def message_metadata(part)
    {
      source: {
        provider: @source.provider,
        **@source.message_source_metadata(part)
      }.compact
    }
  end

  def timestamp_for(value)
    return Time.current if value.blank?

    @source.timestamp_for(value)
  end

  def update_cursor(key, cursor)
    @data_import.with_lock do
      current_cursor = @data_import.cursor.to_h.deep_stringify_keys
      if inactive_import_run?
        @import_stopped = true
        next current_cursor.dig(key, 'starting_after')
      end

      if current_cursor != @persisted_cursor
        @persisted_cursor = current_cursor.deep_dup
        next current_cursor.dig(key, 'starting_after')
      end

      updated_cursor = current_cursor.merge(
        key => { starting_after: cursor, completed: cursor.blank?, updated_at: Time.current.iso8601 }
      ).deep_stringify_keys
      @data_import.update!(cursor: updated_cursor)
      @persisted_cursor = updated_cursor.deep_dup
      cursor
    end
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

  def increment_stat(group, key, amount = 1)
    @stats[group] ||= {}
    @stats[group][key] = @stats[group][key].to_i + amount
  end

  def mark_stat_group_dirty(group)
    @dirty_stat_groups[group] = true
  end

  def reconcile_dirty_stats
    return if @dirty_stat_groups.empty?

    with_query_timeout_retry do
      @dirty_stat_groups.each_key do |group|
        case group
        when 'contacts'
          reconcile_item_stats('contact')
        when 'messages'
          reconcile_message_stats
        else
          raise ArgumentError, "Unsupported #{@source.display_name} import stat group: #{group}"
        end
      end
      persist_stats
    end
    @dirty_stat_groups.clear
  end

  def with_query_timeout_retry
    retries = 0
    begin
      yield
    rescue ActiveRecord::QueryCanceled
      raise if retries >= QUERY_TIMEOUT_RETRY_LIMIT

      retries += 1
      sleep(rand(QUERY_TIMEOUT_RETRY_DELAY_RANGE))
      retry
    end
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
    @data_import.with_lock do
      current_stats = default_stats.deep_merge(@data_import.stats || {})
      reconcile_concurrent_stats(current_stats) if current_stats != @persisted_stats || @data_import.cursor.to_h != @persisted_cursor

      @data_import.update_columns(stats: @stats, updated_at: Time.current)
      @persisted_stats = @stats.deep_dup
    end
  end

  def reconcile_concurrent_stats(current_stats)
    local_stats = @stats
    @stats = current_stats.deep_merge(local_stats)
    %w[contacts conversations messages].each do |group|
      totals = [current_stats.dig(group, 'total'), local_stats.dig(group, 'total')].compact
      @stats[group]['total'] = totals.map(&:to_i).max if totals.any?
    end

    reconcile_item_stats('contact')
    reconcile_item_stats('conversation')
    reconcile_message_stats
    @stats['errors']['count'] = @data_import.import_errors.non_skip_logs.count + @data_import.import_errors.failed.count
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
