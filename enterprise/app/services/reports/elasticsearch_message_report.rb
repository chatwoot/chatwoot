class Reports::ElasticsearchMessageReport
  MESSAGE_TYPES = {
    'incoming_messages_count' => 'incoming',
    'outgoing_messages_count' => 'outgoing'
  }.freeze
  REQUEST_TIMEOUT = 5
  MILLISECONDS_PER_SECOND = 1000

  pattr_initialize [:account!, :metric!, :dimension_type!, :dimension_id!, :range!, :group_by!, :timezone!]

  def aggregate
    result = request(track_total_hits: true)
    return unless result

    result.fetch('hits').fetch('total').fetch('value')
  end

  def timeseries
    result = request(track_total_hits: false, aggs: { messages_by_period: { date_histogram: histogram } })
    return unless result

    result.fetch('aggregations').fetch('messages_by_period').fetch('buckets').map do |bucket|
      { value: bucket.fetch('doc_count'), timestamp: bucket.fetch('key') / MILLISECONDS_PER_SECOND }
    end
  end

  private

  def request(**body)
    result = Searchkick.client.search(
      index: Message.search_index.name,
      body: body.merge(size: 0, timeout: "#{REQUEST_TIMEOUT}s", query: { bool: { filter: filters } })
    )
    if result.fetch('timed_out') || result.fetch('_shards').fetch('failed').positive?
      Rails.logger.warn("Elasticsearch report incomplete for account #{account.id}; falling back to SQL")
      return
    end

    result
  rescue OpenSearch::Transport::Transport::Error, Faraday::TimeoutError, Faraday::ConnectionFailed => e
    Rails.logger.warn("Elasticsearch report failed for account #{account.id}: #{e.class.name}; falling back to SQL")
    nil
  end

  def filters
    clauses = [
      { term: { account_id: account.id } },
      { term: { message_type: MESSAGE_TYPES.fetch(metric.to_s) } },
      { range: { created_at: { gte: range.begin.iso8601(3), lt: range.end.iso8601(3) } } }
    ]
    clauses << { term: { inbox_id: dimension_id } } if dimension_type == 'inbox'
    clauses
  end

  def histogram
    {
      field: 'created_at', calendar_interval: group_by,
      time_zone: ActiveSupport::TimeZone[timezone].tzinfo.name,
      min_doc_count: 0,
      extended_bounds: {
        min: range.begin.iso8601(3),
        max: (range.end.to_time.to_r * MILLISECONDS_PER_SECOND).ceil - 1
      }
    }.tap do |options|
      # Groupdate defaults to Sunday; Elasticsearch calendar weeks start on Monday.
      options[:offset] = "#{(Date::DAYS_INTO_WEEK.fetch(Groupdate.week_start) - 1) % 7}d" if group_by == 'week'
    end
  end
end
