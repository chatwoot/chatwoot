class ReportingEvents::RollupService
  def self.perform(reporting_event)
    new(reporting_event).perform
  end

  def initialize(reporting_event)
    @reporting_event = reporting_event
    @account = reporting_event.account
  end

  def perform
    return unless rollup_enabled?

    rows = build_rollup_rows
    return if rows.empty?

    upsert_rollups(rows)
  end

  private

  # NOTE: This is intentionally not gated by the reporting_events_rollup feature flag.
  # Rollup data is collected for all accounts with a valid reporting timezone (soft toggle).
  # The feature flag only controls the read path — whether reports query rollups or raw events.
  def rollup_enabled?
    @account.reporting_timezone.present? && ActiveSupport::TimeZone[@account.reporting_timezone].present?
  end

  def event_date
    @event_date ||= @reporting_event.created_at.in_time_zone(@account.reporting_timezone).to_date
  end

  def dimensions
    {
      account: @account.id,
      agent: @reporting_event.user_id,
      inbox: @reporting_event.inbox_id
    }
  end

  def build_rollup_rows
    event_metrics = ReportingEvents::EventMetricRegistry.metrics_for(@reporting_event)

    dimensions.each_with_object([]) do |(dimension_type, dimension_id), rows|
      next if dimension_id.nil?

      event_metrics.each do |metric, metric_data|
        rows << rollup_attributes(dimension_type, dimension_id, metric, metric_data)
      end
    end
  end

  def upsert_rollups(rows)
    # rubocop:disable Rails/SkipsModelValidations
    ReportingEventsRollup.upsert_all(
      rows,
      unique_by: [:account_id, :date, :dimension_type, :dimension_id, :metric],
      on_duplicate: upsert_on_duplicate_sql
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  def rollup_attributes(dimension_type, dimension_id, metric, metric_data)
    {
      account_id: @account.id, date: event_date,
      dimension_type: dimension_type, dimension_id: dimension_id, metric: metric,
      count: metric_data[:count], sum_value: metric_data[:sum_value].to_f,
      sum_value_business_hours: metric_data[:sum_value_business_hours].to_f,
      created_at: Time.current, updated_at: Time.current
    }
  end

  def upsert_on_duplicate_sql
    Arel.sql(
      'count = reporting_events_rollups.count + EXCLUDED.count, ' \
      'sum_value = reporting_events_rollups.sum_value + EXCLUDED.sum_value, ' \
      'sum_value_business_hours = reporting_events_rollups.sum_value_business_hours + EXCLUDED.sum_value_business_hours, ' \
      'updated_at = EXCLUDED.updated_at'
    )
  end
end
