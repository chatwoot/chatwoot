# frozen_string_literal: true

class ReportingEvents::BackfillService
  DIMENSIONS = [
    { type: 'account', group_column: nil },
    { type: 'agent',   group_column: :user_id },
    { type: 'inbox',   group_column: :inbox_id }
  ].freeze

  # TODO: Move this to EventMetricRegistry when we expand distinct-counting support.
  # The live path already guards uniqueness in ReportingEventListener#conversation_bot_handoff,
  # but historical duplicates can exist since it's not enforced at the DB level.
  # These events are queried per-dimension (not group-then-sum) because COUNT(DISTINCT) is not additive.
  DISTINCT_COUNT_EVENTS = %w[conversation_bot_handoff].freeze

  DISTINCT_COUNT_SQL = Arel.sql('COUNT(DISTINCT conversation_id)')

  def self.backfill_date(account, date)
    new(account, date).perform
  end

  def initialize(account, date)
    @account = account
    @date = date
  end

  def perform
    start_utc, end_utc = date_boundaries_in_utc
    rollup_rows = build_rollup_rows(start_utc, end_utc)

    ReportingEventsRollup.transaction do
      delete_existing_rollups
      bulk_insert_rollups(rollup_rows) if rollup_rows.any?
    end
  end

  private

  def delete_existing_rollups
    ReportingEventsRollup.where(account_id: @account.id, date: @date).delete_all
  end

  def date_boundaries_in_utc
    tz = ActiveSupport::TimeZone[@account.reporting_timezone]
    start_in_tz = tz.parse(@date.to_s)
    end_in_tz = tz.parse((@date + 1.day).to_s)
    [start_in_tz.utc, end_in_tz.utc]
  end

  def build_rollup_rows(start_utc, end_utc)
    aggregates = build_aggregates(start_utc, end_utc)

    aggregates.map do |(dimension_type, dimension_id, metric), data|
      {
        account_id: @account.id,
        date: @date,
        dimension_type: dimension_type,
        dimension_id: dimension_id,
        metric: metric,
        count: data[:count],
        sum_value: data[:sum_value],
        sum_value_business_hours: data[:sum_value_business_hours],
        created_at: Time.current,
        updated_at: Time.current
      }
    end
  end

  def build_aggregates(start_utc, end_utc)
    aggregates = Hash.new { |h, k| h[k] = { count: 0, sum_value: 0.0, sum_value_business_hours: 0.0 } }
    standard_names = ReportingEvents::EventMetricRegistry.event_names - DISTINCT_COUNT_EVENTS
    base = @account.reporting_events.where(created_at: start_utc...end_utc)

    DIMENSIONS.each do |dimension|
      aggregate_standard_events(aggregates, base.where(name: standard_names), dimension)
      aggregate_distinct_events(aggregates, base.where(name: DISTINCT_COUNT_EVENTS), dimension)
    end

    aggregates
  end

  def aggregate_standard_events(aggregates, scope, dimension)
    group_cols, selects = dimension_groups_and_selects(dimension)

    scope.group(*group_cols).pluck(*selects).each do |row|
      event_name, dimension_id, count, sum_value, sum_value_business_hours = unpack_row(row, dimension)
      next if dimension_id.nil?

      accumulate_metrics(aggregates, dimension[:type], dimension_id, event_name,
                         { count: count, sum_value: sum_value, sum_value_business_hours: sum_value_business_hours })
    end
  end

  def accumulate_metrics(aggregates, dimension_type, dimension_id, event_name, values)
    ReportingEvents::EventMetricRegistry.metrics_for_aggregate(event_name, **values).each do |metric, metric_data|
      key = [dimension_type, dimension_id, metric]
      aggregates[key][:count] += metric_data[:count]
      aggregates[key][:sum_value] += metric_data[:sum_value].to_f
      aggregates[key][:sum_value_business_hours] += metric_data[:sum_value_business_hours].to_f
    end
  end

  def aggregate_distinct_events(aggregates, scope, dimension)
    return if DISTINCT_COUNT_EVENTS.empty?

    group_cols = dimension[:group_column] ? [:name, dimension[:group_column]] : [:name]

    scope.group(*group_cols).pluck(*group_cols, DISTINCT_COUNT_SQL).each do |row|
      event_name, dimension_id, count = dimension[:group_column] ? row : [row[0], @account.id, row[1]]
      next if dimension_id.nil?

      accumulate_metrics(aggregates, dimension[:type], dimension_id, event_name,
                         { count: count, sum_value: 0, sum_value_business_hours: 0 })
    end
  end

  def dimension_groups_and_selects(dimension)
    agg_selects = [Arel.sql('COUNT(*)'), Arel.sql('COALESCE(SUM(value), 0)'), Arel.sql('COALESCE(SUM(value_in_business_hours), 0)')]

    if dimension[:group_column]
      [[:name, dimension[:group_column]], [:name, dimension[:group_column], *agg_selects]]
    else
      [[:name], [:name, *agg_selects]]
    end
  end

  def unpack_row(row, dimension)
    if dimension[:group_column]
      # [name, dimension_id, count, sum_value, sum_value_business_hours]
      row
    else
      # [name, count, sum_value, sum_value_business_hours] → inject account id
      [row[0], @account.id, row[1], row[2], row[3]]
    end
  end

  def bulk_insert_rollups(rollup_rows)
    # rubocop:disable Rails/SkipsModelValidations
    ReportingEventsRollup.insert_all(rollup_rows)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
