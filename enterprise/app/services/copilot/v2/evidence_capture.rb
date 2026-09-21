module Copilot::V2::EvidenceCapture
  # The caller persists this manifest before processing. Never accept it directly from model arguments.
  # Reauthorization below prevents a saved selection from granting access after permissions change.
  # Capture and its exact completeness manifest share one short transaction.
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/ParameterLists
  # rubocop:disable Metrics/BlockLength
  def read_related(selection, relationship:, fields: nil, filters: [], window: nil, customer_only: false)
    membership!
    validate_selection!(selection)
    source = selection.fetch('resource')
    target, foreign_key, parent_key = Copilot::V2::ResourceRegistry.fetch(source)[:relationships].fetch(relationship) do
      raise ArgumentError, 'Unsupported registered relationship'
    end
    fields = checked_fields(target, fields)
    raise ArgumentError, 'customer_only must be boolean' unless [true, false].include?(customer_only)
    raise ArgumentError, 'Message filters apply only to message evidence' if target != 'messages' && (window || customer_only)

    snapshot do
      captured_at = Time.current
      bounds = target == 'messages' ? evidence_window(window, captured_at) : nil
      parents_by_id = scope(source).where(id: selection.fetch('selected_ids')).index_by(&:id)
      parents = selection.fetch('selected_ids').filter_map { |id| parents_by_id[id] }
      relation = filtered_scope(target, filters)
      relation = message_scope(relation, bounds, customer_only) if target == 'messages'
      total_bytes = 0
      items = selection.fetch('selected_ids').map do |id|
        parent = parents_by_id[id]
        next { 'id' => id, 'state' => 'unresolved', 'reason' => 'record_unavailable', 'records' => [] } unless parent

        related = relation.where(foreign_key => parent[parent_key || 'id'])
        item = capture_item(parent, related, target, fields)
        total_bytes += item.to_json.bytesize
        if total_bytes > Copilot::V2::Resources::MAX_SNAPSHOT_BYTES
          item = { 'id' => parent.id, 'state' => 'unresolved', 'reason' => 'snapshot_too_large',
                   'records' => [] }
        end
        item
      end
      watermark = if target == 'messages'
                    @account.messages.where(conversation_id: parents.map(&:id)).reorder(nil)
                            .group(:conversation_id).maximum(:id).transform_keys(&:to_s)
                  else
                    {}
                  end
      complete = selection.dig('selection', 'complete') && items.all? { |item| item['state'] == 'captured' }
      { 'reference_type' => 'evidence', 'resource' => source, 'evidence_resource' => target,
        'identity_type' => 'database_id', 'selected_ids' => selection.fetch('selected_ids'), 'selection' => selection.fetch('selection'),
        'scope' => selection.fetch('scope'), 'relationship' => relationship, 'evidence_filters' => filters,
        'window' => bounds, 'customer_only' => customer_only, 'captured_at' => captured_at.iso8601(6),
        'message_watermarks' => watermark, 'items' => items, 'complete' => complete,
        'resolved_ids' => items.select { |i| i['state'] == 'captured' }.pluck('id'),
        'unresolved_ids' => items.select { |i| i['state'] == 'unresolved' }.pluck('id'),
        'retrieved_count' => items.sum { |i| i.fetch('records').size } }
    end
  end

  # rubocop:enable Metrics/BlockLength
  # rubocop:enable Metrics/ParameterLists
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # Apply the captured filters and watermarks together when counting new arrivals.
  # rubocop:disable Metrics/AbcSize
  def freshness(manifest)
    self.class.require_message_evidence!(manifest)
    membership!
    checked_at = Time.current
    relation = filtered_scope('messages', manifest.fetch('evidence_filters'))
    # Extend the original end boundary to check new arrivals, preserving the same lower bound and speaker filters.
    bounds = manifest.fetch('window').merge('until' => checked_at.iso8601(6))
    relation = message_scope(relation, bounds, manifest.fetch('customer_only'))
    available_ids = scope(manifest.fetch('resource')).where(id: manifest.fetch('selected_ids')).pluck(:id)
    counts = available_ids.to_h do |id|
      watermark = manifest.fetch('message_watermarks').fetch(id.to_s, 0)
      messages = relation.where(conversation_id: id).where(Message.arel_table[:id].gt(watermark))
      [id, messages.where(Message.arel_table[:created_at].gt(Time.iso8601(manifest.fetch('captured_at')))).count]
    end
    { 'checked_at' => checked_at.iso8601(6), 'conversation_count' => counts.count { |_id, count| count.positive? },
      'message_count' => counts.values.sum, 'unavailable_ids' => manifest.fetch('selected_ids') - available_ids,
      'limitations' => ['Does not detect edits, deletions or later transcript updates'] }
  end

  # rubocop:enable Metrics/AbcSize

  private

  def message_scope(relation, bounds, customer_only)
    relation = relation.where(message_type: %w[incoming outgoing], created_at: Time.iso8601(bounds['since'])..Time.iso8601(bounds['until']))
    customer_only ? relation.where(message_type: 'incoming', sender_type: 'Contact', private: false) : relation
  end

  # Drain pages and enforce whole-record evidence bounds in one loop.
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def capture_item(parent, relation, target, fields)
    records = []
    bytes = 0
    cursor = 0
    loop do
      page = relation.where(relation.klass.arel_table[:id].gt(cursor)).reorder(id: :asc).limit(Copilot::V2::Resources::PAGE_SIZE)
      page = page.includes(:attachments, :call, :conversation) if target == 'messages'
      page = page.to_a
      break if page.empty?

      page.each do |record|
        row = target == 'messages' ? Copilot::V2::EvidenceSerializer.message(record) : project(record, fields)
        bytes += row.to_json.bytesize
        if records.size >= Copilot::V2::Resources::MAX_RELATED || bytes > Copilot::V2::Resources::MAX_EVIDENCE_BYTES
          return { 'id' => parent.id, 'state' => 'unresolved', 'reason' => 'evidence_too_large', 'records' => [] }
        end

        records << row
      end
      cursor = page.last.id
    end
    identity = parent.attributes.slice('id', 'display_id', 'contact_id').as_json
    { 'id' => parent.id, 'identity' => identity, 'state' => 'captured', 'records' => records, 'evidence_count' => records.size }
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
