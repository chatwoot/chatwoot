# Reads the dashboard's reports for Copilot through the same V2 builders, so Copilot's numbers match the reports pages.
# A period (day, week, month or year) gives metrics over time for the account or one agent, inbox, team or label. A
# dimension (agent, inbox, team or label) gives the summary the reports pages list for each of them.
class Captain::Copilot::ReportService
  PERIODS = Captain::Copilot::Resources::BaseResource::PERIODS
  DIMENSION_FILTERS = { 'agent' => 'agent_id', 'inbox' => 'inbox_id', 'team' => 'team_id', 'label' => 'label' }.freeze
  SUMMARY_BUILDERS = {
    'agent' => V2::Reports::AgentSummaryBuilder, 'inbox' => V2::Reports::InboxSummaryBuilder,
    'team' => V2::Reports::TeamSummaryBuilder, 'label' => V2::Reports::LabelSummaryBuilder
  }.freeze
  AVERAGES = %w[avg_first_response_time avg_resolution_time reply_time avg_reply_time].freeze
  # A breakdown for each agent, inbox, team or label runs one report each, so it covers the busiest ones.
  MAX_EACH = 20
  SUMMARY_COUNTS = { 'conversations_count' => :conversations, 'resolutions_count' => :resolved }.freeze
  SUMMARY_METRICS = SUMMARY_COUNTS.keys + %w[avg_first_response_time avg_resolution_time reply_time]
  # Chart titles and bar labels name the metric in plain words.
  METRIC_NAMES = {
    'conversations_count' => 'Conversations', 'incoming_messages_count' => 'Messages received',
    'outgoing_messages_count' => 'Messages sent', 'resolutions_count' => 'Resolutions',
    'avg_first_response_time' => 'Average first response time in minutes', 'avg_resolution_time' => 'Average resolution time in minutes',
    'reply_time' => 'Average reply time in minutes', 'bot_resolutions_count' => 'Bot resolutions', 'bot_handoffs_count' => 'Bot handoffs'
  }.freeze
  # One total or average per metric over exactly since to before, for comparing date ranges.
  RANGE = 'range'.freeze
  # The options each kind of report leaves out. Passing one is an error, so the model never reads numbers that skip it.
  IGNORED_OPTIONS = { summary: ['each', *DIMENSION_FILTERS.values], range: %w[each chart],
                      breakdown: [*DIMENSION_FILTERS.values, 'chart'] }.freeze

  def self.permitted?(account:, user:)
    account_user = account.account_users.find_by(user_id: user.id)
    account_user.present? && ReportPolicy.new({ user: user, account: account, account_user: account_user }, :report).view?
  end

  def initialize(account:, tool_call:, business_hours: false, chart: false)
    @account = account
    @tool_call = tool_call
    @business_hours = business_hours
    @chart = chart
    @time_zone = account.reporting_timezone.presence || 'UTC'
  end

  def call(by:, since:, before:, metrics: [], filters: {})
    @since = Time.iso8601(since).in_time_zone(@time_zone)
    @before = Time.iso8601(before).in_time_zone(@time_zone)
    raise ArgumentError, 'since must be earlier than before' if @since >= @before

    kind = report_kind(by, filters)
    reject_ignored_options(kind, by, filters)
    return summary(by, metrics) if kind == :summary
    raise ArgumentError, 'metrics is required to report by range, day, week, month or year' if metrics.blank?
    return range_totals(metrics, filters) if kind == :range

    kind == :breakdown ? breakdown(metrics, by, filters['each']) : timeseries(metrics, by, filters)
  end

  private

  def timeseries(metrics, period, filters)
    type, id = dimension(filters)
    series = metrics.map { |metric| metric_series(metric, period, type, id) }
    result = { by: period, for: id ? "#{type} #{id}" : 'account', metrics: series, time_zone: @time_zone }
    return result unless @chart

    subject = subject_name(type, id)
    result.merge(Captain::Copilot::Chart.for(@tool_call, series.map { |entry| timeseries_chart(entry, period, subject) }))
  end

  def range_totals(metrics, filters)
    type, id = dimension(filters)
    series = metrics.map { |metric| metric_series(metric, 'day', type, id).except(:points) }
    { by: RANGE, for: id ? "#{type} #{id}" : 'account', since: @since.iso8601, before: @before.iso8601, metrics: series, time_zone: @time_zone }
  end

  # data_from and data_to name the first and last periods with any activity, so the agent hears when the data starts
  # after or ends before the range asked about.
  def metric_series(metric, period, type, id)
    builder = V2::Reports::Conversations::ReportBuilder.new(@account, params.merge(type: type, id: id, metric: metric, group_by: period))
    points = builder.timeseries.map { |point| timeseries_point(point, period, metric) }
    active = points.select { |point| point[:value].to_f.positive? }
    { metric: metric, points: points, total_or_average: overall(builder, metric, points),
      data_from: active.first&.dig(:period), data_to: active.last&.dig(:period) }
  end

  # One row per agent, inbox, team or label with activity in the range, each with the metric per period.
  def breakdown(metrics, period, dimension)
    raise ArgumentError, 'each takes one metric' if metrics.size > 1

    active = active(summary_rows(dimension))
    rows = active.first(MAX_EACH).map do |row|
      { name: row[:name], id: row[:id], **metric_series(metrics.first, period, dimension, row[:id]).except(:metric) }
    end
    result = { metric: metrics.first, by: period, each: dimension, rows: rows, time_zone: @time_zone }
    active.size > MAX_EACH ? result.merge(note: "Showing the #{MAX_EACH} busiest of #{active.size}.") : result
  end

  # The summary lists counts and average times; it can chart its two counts. The agents, inboxes, teams or labels with no
  # activity are counted, so an answer about the others is a number, not a guess.
  def summary(dimension, metrics)
    if @chart && !metrics.intersect?(SUMMARY_COUNTS.keys)
      raise ArgumentError, "A chart by #{dimension} needs conversations_count or resolutions_count in metrics"
    end

    all = summary_rows(dimension)
    rows = active(all)
    result = { by: dimension, rows: rows, without_activity: all.size - rows.size, time_zone: @time_zone }
    missing = metrics - SUMMARY_METRICS
    if missing.any?
      result[:note] = "The summary has no #{missing.join(', ')}. For them per #{dimension}, call get_report by day, week, month or " \
                      "year with each set to #{dimension}."
    end
    return result unless @chart

    result.merge(Captain::Copilot::Chart.for(@tool_call, (metrics & SUMMARY_COUNTS.keys).map { |metric| summary_chart(dimension, metric, rows) }))
  end

  # Every agent, inbox, team or label the builder lists, busiest first.
  def summary_rows(dimension)
    builder = SUMMARY_BUILDERS.fetch(dimension) do
      raise ArgumentError, "by must be one of: #{([RANGE] + PERIODS.keys + SUMMARY_BUILDERS.keys).join(', ')}"
    end
    names = dimension_names(dimension)
    rows = builder.new(account: @account, params: params.merge(type: dimension.to_sym)).build
    rows.sort_by { |row| -row[:conversations_count] }.map { |row| summary_row(row, names) }
  end

  # The rows with conversations or resolutions in the range.
  def active(rows)
    rows.select { |row| row[:conversations].positive? || row[:resolved].positive? }
  end

  def params
    { since: @since, until: @before, business_hours: @business_hours, timezone: @time_zone, timezone_offset: offset }
  end

  # The time series builders bucket periods in the zone name; the offset is for builders that take only an offset.
  def offset
    ActiveSupport::TimeZone[@time_zone].now.utc_offset / 3600.0
  end

  def report_kind(by, filters)
    return :range if by == RANGE
    return :summary unless PERIODS.key?(by)

    filters['each'] ? :breakdown : :timeseries
  end

  def reject_ignored_options(kind, by, filters)
    ignored = IGNORED_OPTIONS.fetch(kind, []).select { |option| option == 'chart' ? @chart : filters[option].present? }
    raise ArgumentError, "by #{by}#{' with each' if kind == :breakdown} does not take #{ignored.join(', ')}" if ignored.any?
  end

  # At most one of agent, inbox, team or label, as on the reports pages. Labels are named, the rest are IDs.
  def dimension(filters)
    given = DIMENSION_FILTERS.select { |_, key| filters[key].present? }
    raise ArgumentError, 'Pass at most one of agent_id, inbox_id, team_id or label' if given.size > 1
    return ['account', nil] if given.empty?

    type, key = given.first
    [type, type == 'label' ? @account.labels.find_by!(title: filters[key]).id : filters[key]]
  end

  def timeseries_point(point, period, metric)
    label = period_label(Time.zone.at(point[:timestamp]).in_time_zone(@time_zone), period)
    return label.merge(value: point[:value]) unless AVERAGES.include?(metric)

    label.merge(value: point[:value]&.to_f&.round, duration: duration(point[:value]), events: point[:count])
  end

  # A day is its date. A longer period is its first and last day within since and before, and partial when they cut it.
  def period_label(start, period)
    return { period: start.to_date.iso8601 } if period == 'day'

    finish = start + 1.public_send(period)
    first = [start, @since].max.to_date
    last = ([finish, @before].min - 1.second).to_date
    label = { period: "#{first.iso8601} to #{last.iso8601}" }
    first > start.to_date || last < (finish - 1.second).to_date ? label.merge(partial: true) : label
  end

  def overall(builder, metric, points)
    return points.sum { |point| point[:value] } unless AVERAGES.include?(metric)

    duration(builder.aggregate_value)
  end

  def summary_row(row, names)
    { name: row[:name] || names[row[:id]], id: row[:id], conversations: row[:conversations_count],
      resolved: row[:resolved_conversations_count], avg_first_response_time: duration(row[:avg_first_response_time]),
      avg_resolution_time: duration(row[:avg_resolution_time]), avg_reply_time: duration(row[:avg_reply_time]) }
  end

  # Each bar is labeled by its period's first day.
  def timeseries_chart(entry, period, subject)
    name = METRIC_NAMES.fetch(entry[:metric])
    values = entry[:points].map { |point| AVERAGES.include?(entry[:metric]) ? (point[:value].to_f / 60).round(1) : point[:value] }
    { title: "#{name}#{" for #{subject}" if subject} by #{period}, #{range_text}", label: name,
      points: entry[:points].map { |point| point[:period].first(10) }.zip(values) }
  end

  def summary_chart(dimension, metric, rows)
    name = METRIC_NAMES.fetch(metric)
    { title: "#{name} by #{dimension}, #{range_text}", label: name, points: rows.map { |row| [row[:name], row[SUMMARY_COUNTS[metric]]] } }
  end

  def subject_name(type, id)
    records = { 'agent' => @account.users, 'inbox' => @account.inboxes, 'team' => @account.teams, 'label' => @account.labels }[type]
    records&.find_by(id: id)&.then { |record| record.try(:name) || record.try(:title) }
  end

  # The requested dates in plain words, such as 4 to 10 Sep 2023, for chart titles.
  def range_text
    first = @since.to_date
    last = (@before - 1.second).to_date
    format = if first.year != last.year then '%-d %b %Y'
             elsif first.month != last.month then '%-d %b'
             else
               '%-d'
             end
    "#{first.strftime(format)} to #{last.strftime('%-d %b %Y')}"
  end

  def dimension_names(dimension)
    records = { 'agent' => @account.users, 'inbox' => @account.inboxes, 'team' => @account.teams }[dimension]
    records ? records.pluck(:id, :name).to_h : {}
  end

  def duration(seconds)
    seconds.to_f.positive? ? ActiveSupport::Duration.build(seconds.to_f.round).inspect : nil
  end
end
