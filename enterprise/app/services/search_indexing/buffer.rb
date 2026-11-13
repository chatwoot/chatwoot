class SearchIndexing::Buffer
  BATCH_SIZE = 500
  LEASE_SECONDS = 120
  FLUSH_SECONDS = 30

  attr_reader :entity, :account_id, :epoch

  def initialize(entity:, account_id:, epoch: SearchIndexing::Store.epoch)
    @entity = entity
    @account_id = Integer(account_id)
    @epoch = epoch
    SearchIndexing::Registry.fetch(entity)
  end

  def enqueue(ids)
    return if ids.empty?

    ids.each_slice(BATCH_SIZE) { |batch| execute('enqueue', [Time.current.to_f, *batch.map { |id| Integer(id) }]) }
  end

  def claim(limit: BATCH_SIZE)
    token = SecureRandom.hex(16)
    result = execute('claim', [Time.current.to_f, LEASE_SECONDS, limit, token])
    return if result.empty?

    { token: token, version: result.shift.to_i, revisions: result.each_slice(2).to_h }
  end

  def acknowledge(batch, outcomes)
    execute('acknowledge', [Time.current.to_f, batch.fetch(:token), outcomes.to_json])
  end

  def progress(batch)
    id, revision = batch.fetch(:revisions).first
    saved_revision, cursor = Redis::Alfred.hget(keys[9], id).to_s.split(':')
    saved_revision == revision ? cursor.to_i : 0
  end

  def advance(batch, cursor)
    execute('advance', [Time.current.to_f, batch.fetch(:token), batch.fetch(:revisions).to_json, cursor])
  end

  def statistics
    Redis::Alfred.with do |redis|
      { pending: redis.zcard(keys[0]), failed: redis.hlen(keys[3]), oldest_at: redis.zrange(keys[8], 0, 0, with_scores: true).dig(0, 1) }
    end
  end

  def used?
    Redis::Alfred.exists?(keys[10])
  end

  def retry_failed(cursor: '0')
    execute('retry_failed', [Time.current.to_f, BATCH_SIZE, cursor])
  end

  def stream
    "#{epoch}:#{entity}:#{account_id}"
  end

  private

  def execute(script, arguments)
    result = SearchIndexing::Store.run(script, keys, [epoch, stream, *arguments])
    raise SearchIndexing::StaleGenerationError, 'Search indexing generation changed; restart the backfill' if result == 'stale'

    result
  end

  def keys
    prefix = "#{SearchIndexing::Store::PREFIX}:#{stream}"
    %w[pending revisions claims failed].map { |name| "#{prefix}:#{name}" } +
      [SearchIndexing::Store::REGISTRY_KEY, SearchIndexing::Store::SEQUENCE_KEY, SearchIndexing::Store::EPOCH_KEY,
       "#{prefix}:attempts", "#{prefix}:oldest", "#{prefix}:progress", "#{prefix}:used"]
  end
end
