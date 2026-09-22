class ConversationMonitors::Report
  def initialize(monitor, params)
    @monitor = monitor
    @params = params
    @buckets = ConversationMonitors::Buckets.new(params, default_timezone: monitor.account.reporting_timezone || 'UTC')
  end

  def timeseries
    counts = bucket_counts('matched')
    @incomplete_buckets = bucket_counts(%w[pending error skipped])
    {
      time_basis: 'conversation_created_at', timezone: @buckets.timezone, interval: @buckets.interval,
      data_revision: @monitor.data_revision, total_count: counts.values.sum,
      buckets: @buckets.ranges.each_with_index.map do |range, index|
        { start: range.begin.to_i, end: range.end.to_i, count: counts.fetch(index, 0), covered: covered?(range, index) }
      end
    }
  end

  def conversations
    range = @buckets.range_at(@params[:bucket_start])
    page = current_page
    scope = @monitor.matched_conversations.where(created_at: range)
    total = scope.count
    records = scope.includes(:contact, :inbox, :assignee).order(created_at: :desc, id: :desc).offset((page - 1) * 25).limit(25).to_a
    serializer = V2::Reports::DrilldownRecordSerializer.new(@monitor.account, 'conversations_count', false, records)
    {
      meta: { record_type: 'conversation', total_count: total, conversation_count: total, current_page: page,
              per_page: 25, data_revision: @monitor.data_revision, bucket: { since: range.begin.to_i, until: range.end.to_i } },
      payload: records.map { |record| serializer.serialize(record) }
    }
  end

  private

  def covered?(range, index)
    return false if range.begin < @monitor.history_since || @incomplete_buckets.key?(index)

    @gaps ||= @monitor.scans.select(&:incomplete?)
    @gaps.none? do |scan|
      # Catch-up selects activity, so a skipped pause can affect conversations
      # created before that pause as well as conversations created during it.
      scan.affects_range?(range)
    end
  end

  def current_page
    page = @params[:page] ? ConversationMonitors::Buckets.integer!(@params[:page]) : 1
    raise CustomExceptions::MonitorParametersError, 'invalid_page' unless page.between?(1, 100_000)

    page
  end

  def bucket_counts(statuses)
    conversations = @monitor.account.conversations.where(id: @monitor.evaluations.where(status: statuses).select(:conversation_id))
    scope = conversations.where(created_at: @buckets.since...@buckets.until_time).select(:created_at)
    boundaries = @buckets.ranges.map { |range| range.begin.to_i }.join(',')
    sql = <<~SQL.squish
      SELECT width_bucket(EXTRACT(EPOCH FROM matching.created_at)::double precision,
                          ARRAY[#{boundaries}]::double precision[]) - 1 AS position,
             COUNT(*) AS count
      FROM (#{scope.to_sql}) AS matching
      GROUP BY position
    SQL
    ApplicationRecord.connection.select_all(sql).to_h { |row| [row['position'].to_i, row['count'].to_i] }
  end
end
