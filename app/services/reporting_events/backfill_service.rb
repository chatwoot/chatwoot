# frozen_string_literal: true

class ReportingEvents::BackfillService
  def self.backfill_date(account, date)
    new(account, date).perform
  end

  def initialize(account, date)
    @account = account
    @date = date
    @timezone = account.reporting_timezone
  end

  def perform
    # 1. Delete existing rollups for this date (idempotency)
    delete_existing_rollups

    # 2. Convert date in account timezone to UTC boundaries
    start_utc, end_utc = date_boundaries_in_utc

    # 3. Process each event type with SQL aggregation
    rollup_rows = []
    rollup_rows.concat(aggregate_event_type('conversation_resolved', start_utc, end_utc))
    rollup_rows.concat(aggregate_event_type('first_response', start_utc, end_utc))
    rollup_rows.concat(aggregate_event_type('reply_time', start_utc, end_utc))
    rollup_rows.concat(aggregate_event_type('conversation_bot_resolved', start_utc, end_utc))
    rollup_rows.concat(aggregate_event_type('conversation_bot_handoff', start_utc, end_utc))

    # 4. Bulk insert all rollups at once
    bulk_insert_rollups(rollup_rows) if rollup_rows.any?
  end

  private

  def delete_existing_rollups
    ReportingEventsRollup.where(account_id: @account.id, date: @date).delete_all
  end

  def date_boundaries_in_utc
    tz = ActiveSupport::TimeZone[@timezone]
    start_in_tz = tz.parse(@date.to_s)
    end_in_tz = start_in_tz + 1.day
    [start_in_tz.utc, end_in_tz.utc]
  end

  def aggregate_event_type(event_name, start_utc, end_utc)
    events = @account.reporting_events
                     .where(name: event_name, created_at: start_utc...end_utc)
                     .includes(:conversation)

    return [] if events.empty?

    # Build in-memory aggregates by dimension
    aggregates = build_aggregates(events, event_name)

    # Convert to rollup row hashes
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

  def build_aggregates(events, event_name)
    aggregates = Hash.new { |h, k| h[k] = { count: 0, sum_value: 0.0, sum_value_business_hours: 0.0 } }

    events.each do |event|
      metrics = metrics_for_event(event_name, event)
      dimensions = dimensions_for_event(event)

      metrics.each do |metric, metric_data|
        dimensions.each do |dimension_type, dimension_id|
          next if dimension_id.nil?

          key = [dimension_type, dimension_id, metric]
          aggregates[key][:count] += metric_data[:count]
          aggregates[key][:sum_value] += metric_data[:sum_value]
          aggregates[key][:sum_value_business_hours] += metric_data[:sum_value_business_hours]
        end
      end
    end

    aggregates
  end

  def dimensions_for_event(event)
    {
      'account' => @account.id,
      'agent' => event.user_id,
      'inbox' => event.inbox_id,
      'team' => event.conversation&.team_id
    }
  end

  def metrics_for_event(event_name, event)
    case event_name
    when 'conversation_resolved'
      {
        'resolutions_count' => { count: 1, sum_value: 0, sum_value_business_hours: 0 },
        'resolution_time' => { count: 1, sum_value: event.value, sum_value_business_hours: event.value_in_business_hours }
      }
    when 'first_response'
      { 'first_response' => { count: 1, sum_value: event.value, sum_value_business_hours: event.value_in_business_hours } }
    when 'reply_time'
      { 'reply_time' => { count: 1, sum_value: event.value, sum_value_business_hours: event.value_in_business_hours } }
    when 'conversation_bot_resolved'
      { 'bot_resolutions_count' => { count: 1, sum_value: 0, sum_value_business_hours: 0 } }
    when 'conversation_bot_handoff'
      { 'bot_handoffs_count' => { count: 1, sum_value: 0, sum_value_business_hours: 0 } }
    else
      {}
    end
  end

  def bulk_insert_rollups(rollup_rows)
    # rubocop:disable Rails/SkipsModelValidations
    ReportingEventsRollup.insert_all(rollup_rows)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
