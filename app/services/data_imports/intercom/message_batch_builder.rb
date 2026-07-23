class DataImports::Intercom::MessageBatchBuilder
  PROVIDER = 'intercom'.freeze
  REGULAR_PART_TYPES = %w[comment note source].freeze

  Entry = Struct.new(:source_id, :part, :position, :mapping, :message, :classification, keyword_init: true) do
    def source?
      part['part_type'] == 'source'
    end
  end

  Batch = Struct.new(:items, keyword_init: true) do
    def entries
      items
    end

    def source_entries
      items.select(&:source?)
    end

    def part_entries
      items.reject(&:source?)
    end
  end

  def self.activity_part?(part)
    part_type = part['part_type'].to_s
    part_type.present? && REGULAR_PART_TYPES.exclude?(part_type)
  end

  def self.source_message_importable?(source)
    source['body'].present? || source['subject'].present? || source['attachments'].present?
  end

  def initialize(data_import:, conversation:, source_conversation:)
    @data_import = data_import
    @account = data_import.account
    @conversation = conversation
    @source_conversation = source_conversation
  end

  def perform(source_entries = unprepared_entries)
    classify(source_entries)
  end

  def refresh(entries)
    classify(entries.map do |entry|
      { source_id: entry.source_id, part: entry.part, position: entry.position }
    end)
  end

  def unprepared_entries
    ordered_source_entries.map.with_index { |entry, position| entry.merge(position: position) }
  end

  private

  def classify(source_entries)
    return Batch.new(items: []) if source_entries.empty?

    mappings = message_mappings(source_entries)
    messages = messages_for(source_entries, mappings)

    Batch.new(items: source_entries.map.with_index do |source_entry, position|
      build_entry(source_entry, source_entry.fetch(:position, position), mappings, messages)
    end)
  end

  def ordered_source_entries
    entries = []
    source = @source_conversation['source'].to_h
    if self.class.source_message_importable?(source)
      entries << {
        source_id: "conversation:#{source_conversation_id}:source:#{source['id'].presence || 'initial'}",
        part: source.merge('part_type' => 'source', 'created_at' => @source_conversation['created_at'])
      }
    end

    conversation_parts.each do |part|
      entries << { source_id: "conversation:#{source_conversation_id}:part:#{part['id']}", part: part }
    end
    entries
  end

  def conversation_parts
    Array(@source_conversation.dig('conversation_parts', 'conversation_parts'))
  end

  def source_conversation_id
    @source_conversation['id'].presence || @source_conversation['external_id'].presence || @source_conversation['email'].presence
  end

  def message_mappings(source_entries)
    DataImportMapping.where(
      account: @account,
      source_provider: PROVIDER,
      source_object_type: 'message',
      source_object_id: source_entries.pluck(:source_id)
    ).index_by(&:source_object_id)
  end

  def messages_for(source_entries, mappings)
    mapped_message_ids = mappings.values.filter_map do |mapping|
      mapping.chatwoot_record_id if mapping.chatwoot_record_type == 'Message'
    end
    chatwoot_source_ids = source_entries.map { |entry| "intercom:#{entry[:source_id]}" }
    messages = Message.where(id: mapped_message_ids).or(
      Message.where(conversation_id: @conversation.id, source_id: chatwoot_source_ids)
    ).to_a

    {
      by_id: messages.index_by(&:id),
      by_source_id: messages.index_by(&:source_id)
    }
  end

  def build_entry(source_entry, position, mappings, messages)
    source_id = source_entry[:source_id]
    mapping = mappings[source_id]
    mapped_message = messages[:by_id][mapping.chatwoot_record_id] if mapping&.chatwoot_record_type == 'Message'
    existing_message = messages[:by_source_id]["intercom:#{source_id}"]

    Entry.new(
      source_id: source_id,
      part: source_entry[:part],
      position: position,
      mapping: mapping,
      message: mapped_message || existing_message,
      classification: classification_for(mapping, mapped_message, existing_message, source_entry[:part])
    )
  end

  def classification_for(mapping, mapped_message, existing_message, part)
    return existing_message.present? ? :existing_message : :new_message if mapping.blank?
    return :repairable_stale_mapping unless mapping_handled?(mapping, mapped_message, part)

    mapping.data_import_id == @data_import.id ? :current_import : :previous_import
  end

  def mapping_handled?(mapping, mapped_message, part)
    return false if mapping.metadata['skipped'] && self.class.activity_part?(part)

    mapping.metadata['skipped'] || mapped_message.present?
  end
end
