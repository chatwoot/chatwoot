class SearchIndexing::Backfill
  MAX_PENDING = 2_000

  def self.start(account:, entity:, reconcile: false)
    raise ArgumentError, 'Enable indexing for this account first' unless SearchIndexing::Producer.eligible?(entity, account)

    definition = SearchIndexing::Registry::DOCUMENTS.fetch(entity).constantize
    state = SearchIndexing::IndexState.create_or_find_by!(account_id: account.id, entity: entity) do |entry|
      entry.assign_attributes(epoch: SearchIndexing::Store.epoch, schema_version: definition::SCHEMA_VERSION, run_token: SecureRandom.hex(16))
    end
    state.with_lock do
      ready_at = state.ready_at if reconcile && state.readable?
      state.update!(epoch: SearchIndexing::Store.epoch, schema_version: definition::SCHEMA_VERSION, run_token: SecureRandom.hex(16),
                    status: 'running', phase: ready_at ? 'verify_source' : 'scan', cursor: 0,
                    upper_id: definition.scope(account.id).maximum(:id) || 0,
                    scanned_count: 0, repaired_count: 0, pass_repairs: 0, ready_at: ready_at, last_error: nil)
    end
    SearchIndexing::BackfillJob.perform_later(state.id, state.run_token)
    state
  end

  def initialize(state)
    @state = state
    @document = state.document
    @buffer = state.buffer
  end

  def perform
    return @state.invalidate! unless eligible_generation?
    return @state.update!(status: 'failed', ready_at: nil, last_error: 'bulk_item_failure') if @buffer.statistics[:failed].positive?
    return if @buffer.statistics[:pending] > MAX_PENDING

    @document.ensure_index!(@state.epoch)
    transition('verify_index') if !@state.account && @state.phase.in?(%w[scan verify_source])
    send("perform_#{@state.phase}")
  end

  private

  def eligible_generation?
    return false unless @state.epoch == SearchIndexing::Store.epoch && @state.schema_version == @document.class::SCHEMA_VERSION

    !@state.account || SearchIndexing::Producer.eligible?(@state.entity, @state.account)
  end

  def source_page
    scope = @document.class.scope(@state.account_id)
    scope.where(scope.klass.arel_table[:id].gt(@state.cursor))
         .where(scope.klass.arel_table[:id].lteq(@state.upper_id)).order(:id).limit(SearchIndexing::Buffer::BATCH_SIZE)
  end

  def perform_scan
    ids = source_page.pluck(:id)
    return transition('verify_source') if ids.empty?

    @buffer.enqueue(ids)
    @state.update!(cursor: ids.last, scanned_count: @state.scanned_count + ids.length)
  end

  def perform_verify_source
    return unless drained?

    ids = source_page.pluck(:id)
    return transition('verify_index') if ids.empty?

    records = @document.records(ids).to_a
    repair(mismatched_ids(records)) if records.any?
    @state.update!(cursor: ids.last)
  end

  def mismatched_ids(records)
    indexed = Searchkick.client.mget(index: @document.index_name(@state.epoch), body: { ids: records.map(&:id) }).fetch('docs')
    records.zip(indexed).filter_map do |record, result|
      expected = JSON.parse(@document.serialize(record).merge(deleted: false).to_json)
      record.id unless result['found'] && result['_source'] == expected
    end
  end

  def perform_verify_index
    return unless drained?

    response = Searchkick.client.search(index: @document.index_name(@state.epoch), allow_partial_search_results: false, body: orphan_query)
    verify_complete_response!(response)
    ids = response.fetch('hits').fetch('hits').map { |hit| Integer(hit.fetch('_id')) }
    return transition('drain') if ids.empty?

    repair(ids - @document.records(ids).pluck(:id))
    @state.update!(cursor: ids.max)
  end

  def orphan_query
    filters = [{ term: { account_id: @state.account_id } }, { term: { deleted: false } }, { range: { id: { gt: @state.cursor } } }]
    {
      size: SearchIndexing::Buffer::BATCH_SIZE, _source: false, sort: [{ id: 'asc' }],
      query: { bool: { filter: filters } }
    }
  end

  def perform_drain
    return unless drained?

    if @state.pass_repairs.positive? && @state.account
      @state.update!(phase: 'verify_source', cursor: 0, pass_repairs: 0)
    else
      @state.update!(status: @state.account ? 'ready' : 'purged', ready_at: @state.account ? Time.current : nil, last_error: nil)
    end
  end

  def drained?
    return false unless @buffer.statistics[:pending].zero?

    dependencies = SearchIndexing::Buffer.new(entity: 'contact_conversations', account_id: @state.account_id, epoch: @state.epoch)
    return false unless @state.entity != 'conversations' || dependencies.statistics[:pending].zero?

    verify_complete_response!(Searchkick.client.indices.refresh(index: @document.index_name(@state.epoch)))
    true
  end

  def verify_complete_response!(response)
    return unless response['timed_out'] || response.fetch('_shards').fetch('failed').positive?

    raise Searchkick::Error, 'Search verification returned an incomplete response'
  end

  def repair(ids)
    return if ids.empty?

    @buffer.enqueue(ids)
    @state.update!(pass_repairs: @state.pass_repairs + ids.length, repaired_count: @state.repaired_count + ids.length, ready_at: nil)
  end

  def transition(phase)
    @state.update!(phase: phase, cursor: 0)
  end
end
