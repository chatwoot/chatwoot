# frozen_string_literal: true

class ReportingEvents::BackfillService
  AGGREGATE_SELECTS = [
    :name,
    :user_id,
    :inbox_id,
    Arel.sql('COUNT(*)'),
    Arel.sql('COALESCE(SUM(value), 0)'),
    Arel.sql('COALESCE(SUM(value_in_business_hours), 0)')
  ].freeze

  def self.backfill_date(account, date)
    new(account, date).perform
  end

  def initialize(account, date)
    @account = account
    @date = date
  end

  def perform
    delete_existing_rollups
    start_utc, end_utc = date_boundaries_in_utc
    rollup_rows = build_rollup_rows(start_utc, end_utc)
    bulk_insert_rollups(rollup_rows) if rollup_rows.any?
  end

  private

  def delete_existing_rollups
    ReportingEventsRollup.where(account_id: @account.id, date: @date).delete_all
  end

  def date_boundaries_in_utc
    tz = ActiveSupport::TimeZone[@account.reporting_timezone]
    start_in_tz = tz.parse(@date.to_s)
    end_in_tz = start_in_tz + 1.day
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

    grouped_events(start_utc, end_utc).each { |grouped_event| accumulate_grouped_aggregates(aggregates, grouped_event) }

    aggregates
  end

  def grouped_events(start_utc, end_utc)
    @account.reporting_events
            .where(name: ReportingEvents::MetricRegistry::EVENT_METRICS.keys, created_at: start_utc...end_utc)
            .group(:name, :user_id, :inbox_id)
            .pluck(*AGGREGATE_SELECTS)
            .map { |grouped_row| grouped_event_attributes(grouped_row) }
  end

  def dimensions(grouped_event)
    {
      'account' => @account.id,
      'agent' => grouped_event[:user_id],
      'inbox' => grouped_event[:inbox_id]
    }
  end

  def accumulate_grouped_aggregates(aggregates, grouped_event)
    ReportingEvents::MetricRegistry.event_metrics_for_aggregate(
      grouped_event[:event_name],
      count: grouped_event[:count],
      sum_value: grouped_event[:sum_value],
      sum_value_business_hours: grouped_event[:sum_value_business_hours]
    ).each do |metric, metric_data|
      accumulate_metric_aggregates(aggregates, dimensions(grouped_event), metric, metric_data)
    end
  end

  def grouped_event_attributes(grouped_row)
    event_name, user_id, inbox_id, count, sum_value, sum_value_business_hours = grouped_row

    {
      event_name: event_name,
      user_id: user_id,
      inbox_id: inbox_id,
      count: count,
      sum_value: sum_value,
      sum_value_business_hours: sum_value_business_hours
    }
  end

  def accumulate_metric_aggregates(aggregates, dimensions, metric, metric_data)
    dimensions.each do |dimension_type, dimension_id|
      next if dimension_id.nil?

      key = [dimension_type, dimension_id, metric]
      aggregates[key][:count] += metric_data[:count]
      aggregates[key][:sum_value] += metric_data[:sum_value].to_f
      aggregates[key][:sum_value_business_hours] += metric_data[:sum_value_business_hours].to_f
    end
  end

  def bulk_insert_rollups(rollup_rows)
    # rubocop:disable Rails/SkipsModelValidations
    ReportingEventsRollup.insert_all(rollup_rows)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
