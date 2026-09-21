class Copilot::V2::Results
  def initialize(run)
    @run = run
  end

  def projection(key) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    manifest = @run.datasets.fetch(key)
    items = @run.copilot_run_items.where(dataset_key: key).includes(:source_item).order(:position)
    if manifest['reference_type'] == 'selection'
      return manifest.merge('rows' => items.reject { |item| item.state == 'unresolved' }.map(&:captured),
                            'processing_complete' => items.none? { |item| item.state == 'unresolved' },
                            'unresolved_ids' => items.select { |item| item.state == 'unresolved' }.map { |item| item.captured.fetch('id') })
    end
    return manifest if manifest['reference_type'] == 'aggregate'
    raise ArgumentError, 'Publish selection, analysis or aggregate results' unless manifest['reference_type'] == 'result'

    resolved = items.select { |item| item.state == 'resolved' }
    selected_ids = items.map { |item| item.evidence.fetch('id') }
    resolved_ids = resolved.map { |item| item.evidence.fetch('id') }
    rows = resolved.map { |item| item.result.merge('identity' => item.evidence.fetch('identity', { 'id' => item.evidence.fetch('id') })) }
    source = @run.datasets.fetch(manifest.fetch('source_ref'))
    unresolved = items.reject { |item| item.state == 'resolved' }
    limitations = items.flat_map { |item| item.evidence.fetch('records', []).flat_map { |record| Array(record['limitations']) } }.uniq
    manifest.merge('scope' => source['scope'], 'window' => source['window'], 'captured_at' => source['captured_at'],
                   'evidence_filters' => source['evidence_filters'], 'selection' => source['selection'],
                   'rows' => rows, 'selected_ids' => selected_ids, 'resolved_ids' => resolved_ids,
                   'unresolved_ids' => selected_ids - resolved_ids,
                   'unresolved' => unresolved.map { |item| { 'id' => item.evidence.fetch('id'), 'reason' => item.reason } },
                   'selection_complete' => source.dig('selection', 'complete') == true,
                   'processing_complete' => selected_ids.sort == resolved_ids.sort,
                   'selected_count' => selected_ids.size, 'resolved_count' => resolved_ids.size,
                   'match_count' => rows.count { |row| row['decision'] == 'match' },
                   'no_match_count' => rows.count { |row| row['decision'] == 'no_match' },
                   'uncertain_count' => rows.count { |row| row['decision'] == 'uncertain' },
                   'retrieved_evidence_count' => items.sum { |item| item.evidence.fetch('records', []).size },
                   'supplied_evidence_count' => items.select(&:supplied).sum { |item| item.evidence.fetch('records', []).size },
                   'evidence_limitations' => limitations)
  end

  def aggregate(key, group_by:, unit:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    source = projection(key)
    rows = source.fetch('rows')
    type = source.fetch('reference_type')
    allowed = if type == 'result'
                ['decision'] + source.fetch('specification').fetch('fields').pluck('name')
              else
                source.fetch('scope').fetch('fields') - %w[content custom_attributes]
              end
    raise ArgumentError, 'Unregistered aggregation field' unless (group_by - allowed).empty?
    raise ArgumentError, 'Customer identity is unavailable' if unit == 'customers' && rows.any? { |row| contact_id(row, source).nil? }

    groups = rows.group_by { |row| group_by.map { |field| row.fetch('values', {}).fetch(field) { row[field] } } }
    counts = groups.map do |values, members|
      { 'group' => group_by.zip(values).to_h,
        'count' => unit == 'customers' ? members.map { |row| contact_id(row, source) }.uniq.size : members.size }
    end
    { 'reference_type' => 'aggregate', 'source_ref' => key, 'unit' => unit, 'group_by' => group_by, 'groups' => counts,
      'denominator' => unit == 'customers' ? rows.map { |row| contact_id(row, source) }.uniq.size : rows.size,
      'selection_complete' => source['selection_complete'] || source.dig('selection', 'complete') == true,
      'processing_complete' => source['processing_complete'] == true,
      'denominator_scope' => 'Only resolved rows in this stored result; partial results do not represent the whole requested scope',
      'group_overlap' => unit == 'customers' ? 'Customers may occur in multiple groups. Do not sum groups as unique customers.' : nil }
  end

  def saved_summary(reason: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    keys = Array(@run.checkpoint['published_refs'])
    if keys.empty?
      analyses = @run.datasets.select { |_key, value| value['reference_type'] == 'result' }
      keys = analyses.group_by { |_key, value| value['source_ref'] }.values.map { |entries| entries.last.first }
    end
    results = keys.map do |key|
      value = projection(key).merge('reference' => key)
      Array(value['unresolved']).each { |item| item['reason'] ||= reason || 'not_processed' }
      value
    end
    { 'results' => results, 'reason' => reason, 'answer' => @run.result_summary['answer'],
      'partial' => reason.present?,
      'usage_note' => 'Supplied counts mean provider attempts, including lost in-flight requests; receipt is not guaranteed.' }
  end

  private

  def contact_id(row, source)
    return row['id'] if source['resource'] == 'contacts' && source['reference_type'] == 'selection'

    row.dig('identity', 'contact_id') || row['contact_id']
  end
end
