class Copilot::V2::Operations
  def initialize(runner)
    @runner = runner
    @run = runner.run
    @resources = runner.resources
  end

  def perform(operation)
    name = operation.fetch('name')
    arguments = operation.fetch('arguments').deep_stringify_keys
    Copilot::V2::Tool.validate!(name, arguments)
    key = "run#{@run.id}:operation#{@run.checkpoint.fetch('operations').index { |entry| entry['id'] == operation['id'] }}"
    result = dispatch(name, arguments, key)
    @runner.finish_operation(operation, result) if result
  rescue Pundit::NotAuthorizedError
    @runner.authorize!
    @runner.finish_operation(operation, { 'error' => 'This read capability is not permitted', 'code' => 'access_denied' })
  rescue ArgumentError, KeyError => e
    @runner.finish_operation(operation, { 'error' => e.message, 'code' => 'invalid_operation' })
  end

  def refresh_visible_results! # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    changed = false
    Array(@run.checkpoint['published_refs']).each do |key|
      ensure_authorized_projection!(key)
      projection = Copilot::V2::Results.new(@run).projection(key)
      previous = @run.checkpoint.fetch('published_results', {})[key]
      next if previous && previous.except('freshness') == projection

      changed = true
      @runner.commit! do
        checkpoint = @run.checkpoint.deep_dup
        checkpoint['published_results'] = checkpoint.fetch('published_results', {}).merge(key => projection)
        checkpoint.fetch('operations').each do |operation|
          next unless operation['name'] == 'show_results' && operation.dig('arguments', 'result_ref') == key && operation['state'] == 'done'

          operation['result'] = projection.merge('reference' => key)
          entry = checkpoint['transcript'].find { |item| item['tool_call_id'] == operation['id'] }
          entry['content'] = operation['result'].to_json if entry
        end
        @run.update!(checkpoint: checkpoint)
      end
    end
    changed
  end

  private

  def dispatch(name, arguments, key) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    return @resources.catalog if name == 'resource_catalog'

    case name
    when 'select_resources'
      store_capture(key) { @resources.select(**arguments.symbolize_keys) }
    when 'read_related'
      selection = reference(arguments.delete('selection_ref'))
      store_capture(key) { @resources.read_related(selection, **arguments.symbolize_keys) }
    when 'analyze_records'
      source_key = arguments.delete('evidence_ref')
      source = reference(source_key)
      raise ArgumentError, 'Text evidence reference required' unless source['reference_type'] == 'evidence'

      Copilot::V2::Resources.require_message_evidence!(source) if source['resource'] == 'conversations'
      existing = @run.datasets.find do |_ref, data|
        data['reference_type'] == 'result' && data['source_ref'] == source_key && data['specification'] == arguments
      end
      Copilot::V2::Analyzer.new(@runner).process(existing ? existing.first : key, source_key, source, arguments)
    when 'aggregate_results'
      source_key = arguments.delete('result_ref')
      reference(source_key)
      ensure_authorized_projection!(source_key)
      unless @run.datasets.key?(key)
        value = Copilot::V2::Results.new(@run).aggregate(source_key, **arguments.symbolize_keys)
        @runner.commit! { @run.update!(datasets: @run.datasets.merge(key => value)) }
      end
      @run.datasets.fetch(key).merge('reference' => key)
    when 'show_results'
      publish(arguments.fetch('result_ref'), supersedes_ref: arguments['supersedes_ref'])
    end
  end

  def store_capture(key)
    unless @run.datasets.key?(key)
      value = yield
      @runner.commit! do
        persist_items(key, value)
        @run.update!(datasets: @run.datasets.merge(key => value.except('rows', 'items')))
      end
    end
    @run.datasets.fetch(key).merge('reference' => key)
  end

  def persist_items(key, value)
    rows = value['reference_type'] == 'selection' ? value.fetch('rows') : value.fetch('items')
    rows.each_with_index do |row, position|
      @run.copilot_run_items.create!(dataset_key: key, resource_type: value.fetch('resource'), resource_id: row.fetch('id').to_s,
                                     position: position, captured: row, state: row.fetch('state', 'captured'), reason: row['reason'])
    end
  end

  def reference(key)
    import_reference(key) unless @run.datasets.key?(key)
    @runner.manifest(key)
  end

  def import_reference(key) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # Only known same-thread references from the captured follow-up context can be imported.
    raise ArgumentError, 'Unknown thread reference' unless @run.checkpoint.fetch('reference_context', {}).key?(key)

    owner = @run.copilot_thread.copilot_runs.where.not(id: @run.id).order(id: :desc).detect { |old| old.datasets.key?(key) }
    raise ArgumentError, 'Unknown thread reference' unless owner

    value = owner.datasets.fetch(key)
    import_reference(value['source_ref']) if value['source_ref'] && !@run.datasets.key?(value['source_ref'])
    @runner.commit! do
      owner.copilot_run_items.where(dataset_key: key).order(:position).each do |item|
        source = (@run.copilot_run_items.find_by!(dataset_key: value.fetch('source_ref'), resource_id: item.resource_id) if item.source_item)
        @run.copilot_run_items.create!(item.attributes.slice('dataset_key', 'resource_type', 'resource_id', 'position', 'captured', 'state',
                                                             'result', 'reason', 'attempts', 'supplied').merge('source_item' => source))
      end
      @run.update!(datasets: @run.datasets.merge(key => value))
    end
  end

  def ensure_authorized_projection!(key) # rubocop:disable Metrics/AbcSize
    value = @run.datasets.fetch(key)
    if value['reference_type'] == 'aggregate'
      ensure_authorized_projection!(value.fetch('source_ref'))
      updated = Copilot::V2::Results.new(@run).aggregate(value.fetch('source_ref'), group_by: value.fetch('group_by'), unit: value.fetch('unit'))
      @runner.commit! { @run.update!(datasets: @run.datasets.merge(key => updated)) }
      return
    end
    source_key = value['reference_type'] == 'result' ? value.fetch('source_ref') : key
    source = @runner.manifest(source_key)
    @run.copilot_run_items.where(dataset_key: key).where.not(state: 'unresolved').each do |item|
      @resources.authorize_manifest!(source, item_ids: [item.evidence.fetch('id')])
    rescue Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound
      @runner.commit! { item.update!(state: 'unresolved', reason: 'record_unavailable') }
    end
  end

  def publish(key, supersedes_ref: nil) # rubocop:disable Metrics/AbcSize
    reference(key)
    ensure_authorized_projection!(key)
    value = Copilot::V2::Results.new(@run).projection(key)
    source_key = value['source_ref']
    source = source_key ? @run.datasets.fetch(source_key) : value
    source = @run.datasets.fetch(source.fetch('source_ref')) while source['reference_type'] == 'result'
    value['freshness'] = @resources.freshness(source) if source['reference_type'] == 'evidence' && source['evidence_resource'] == 'messages'
    @runner.commit! do
      checkpoint = @run.checkpoint.deep_dup
      refs = Array(checkpoint['published_refs'])
      if supersedes_ref
        raise ArgumentError, 'Superseded reference must be published in this run' unless refs.include?(supersedes_ref)

        refs.delete(supersedes_ref)
      end
      checkpoint['published_refs'] = (refs + [key]).uniq
      checkpoint['published_results'] = checkpoint.fetch('published_results', {}).merge(key => value)
      @run.update!(checkpoint: checkpoint)
    end
    value.merge('reference' => key)
  end
end
