class SearchIndexing::BulkWriter
  MAX_BYTES = 5.megabytes

  def initialize(document:, epoch:)
    @document = document
    @epoch = epoch
  end

  def perform(batch)
    @document.ensure_index!(@epoch)
    records = @document.records(batch.fetch(:revisions).keys).index_by { |record| record.id.to_s }
    items = batch.fetch(:revisions).map do |id, revision|
      build_item(id, revision, records[id], batch.fetch(:version))
    end
    oversized, items = items.partition { |item| item.fetch(:body).bytesize > MAX_BYTES }
    outcomes = oversized.map { |item| outcome(item, 'failed', 'document_too_large') }
    chunks(items).each { |chunk| outcomes.concat(write(chunk)) }
    outcomes
  end

  private

  def build_item(id, revision, record, version)
    metadata = { index: { _index: @document.index_name(@epoch), _id: id, version: version, version_type: 'external' } }
    data = record ? @document.serialize(record).merge(deleted: false) : { account_id: @document.account_id, deleted: true }
    { id: id, revision: revision, body: "#{metadata.to_json}\n#{data.to_json}\n" }
  end

  def chunks(items)
    items.each_with_object([[]]) do |item, groups|
      groups << [] if groups.last.sum { |entry| entry.fetch(:body).bytesize } + item.fetch(:body).bytesize > MAX_BYTES
      groups.last << item
    end.reject(&:empty?)
  end

  def write(items)
    response = Searchkick.client.bulk(body: items.pluck(:body).join, refresh: false)
    response.fetch('items').zip(items).map do |result, item|
      status = result.fetch('index').fetch('status')
      state = if status.between?(200, 299) || status == 409
                'success'
              elsif status == 429 || status >= 500
                'retry'
              else
                'failed'
              end
      outcome(item, state, result.fetch('index').dig('error', 'type'))
    end
  end

  def outcome(item, state, error)
    item.slice(:id, :revision).merge(state: state, error: error)
  end
end
