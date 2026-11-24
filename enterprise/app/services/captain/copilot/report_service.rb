# Reads the dashboard's reports for Copilot through the same V2 builders, so Copilot's numbers match the reports pages.
# A period (day, week, month or year) gives metrics over time for the account or one agent, inbox, team or label. A
# dimension (agent, inbox, team or label) gives the summary the reports pages list for each of them.
class Captain::Copilot::ReportService
  include Captain::Copilot::ReportLabels

  PERIODS = Captain::Copilot::Aggregation::PERIODS
  DIMENSION_FILTERS = { 'agent' => 'agent_id', 'inbox' => 'inbox_id', 'team' => 'team_id', 'label' => 'label' }.freeze
  SUMMARY_BUILDERS = {
    'agent' => V2::Reports::AgentSummaryBuilder, 'inbox' => V2::Reports::InboxSummaryBuilder,
    'team' => V2::Reports::TeamSummaryBuilder, 'label' => V2::Reports::LabelSummaryBuilder
  }.freeze
  AVERAGES = %w[avg_first_response_time avg_resolution_time reply_time avg_reply_time].freeze
  # The label summary gives 0 for an average with no events, so a label's zero average is read as missing.
  LABEL_TIMES = %i[avg_first_response_time avg_resolution_time avg_reply_time].freeze
  # A breakdown runs one report for each agent, inbox, team or label it checks, so it checks the MAX_CHECKED with the most
  # messages sent for that metric, or else with the most conversations, and lists the MAX_EACH with the most of the metric.
  MAX_CHECKED = 50
  MAX_EACH = 20
  SUMMARY_COUNTS = { 'conversations_count' => :conversations, 'resolutions_count' => :resolved }.freeze
  # The summary column behind each metric, so the rows come ranked by the metric the agent asked about. The model
  # misordered written durations such as "1 week and 13 hours" against "1 week and 2 days".
  SUMMARY_COLUMNS = { 'resolutions_count' => :resolved_conversations_count, 'reply_time' => :avg_reply_time }
                    .merge(%w[conversations_count avg_first_response_time avg_resolution_time].index_with(&:to_sym)).freeze
  # Chart titles and bar labels name the metric in plain words.
  METRIC_NAMES = {
    'conversations_count' => 'Conversations', 'incoming_messages_count' => 'Messages received',
    'outgoing_messages_count' => 'Messages sent', 'resolutions_count' => 'Resolutions',
    'avg_first_response_time' => 'Average first response time in minutes', 'avg_resolution_time' => 'Average resolution time in minutes',
    'reply_time' => 'Average reply time in minutes', 'bot_resolutions_count' => 'Bot resolutions', 'bot_handoffs_count' => 'Bot handoffs'
  }.freeze
  # One total or average per metric over exactly since to the last day, for comparing date ranges.
  RANGE = 'range'.freeze
  # The options each kind of report leaves out. Passing one is an error, so the model never reads numbers that skip it.
  IGNORED_OPTIONS = { summary: ['each', *DIMENSION_FILTERS.values], range: %w[each chart order],
                      breakdown: [*DIMENSION_FILTERS.values, 'chart', 'order'], timeseries: %w[order] }.freeze

  def initialize(account:, tool_call:, business_hours: false, chart: false)
    @account = account
    @tool_call = tool_call
    @business_hours = business_hours
    @chart = chart
    @time_zone = account.report_time_zone
  end

  # since is the first day and last_day the last day included, as the reports pages pick dates. Each day starts at
  # midnight in the reporting time zone with that date's own offset; @before is the midnight after the last day.
  def call(by:, since:, last_day:, metrics: [], filters: {})
    @since = Date.iso8601(since).in_time_zone(@time_zone)
    @before = Date.iso8601(last_day).next_day.in_time_zone(@time_zone)
    raise ArgumentError, 'since must not be after until' if @since >= @before

    kind = report_kind(by, filters)
    reject_ignored_options(kind, by, filters)
    return summary(by, metrics, filters['order']) if kind == :summary
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
    { by: RANGE, for: id ? "#{type} #{id}" : 'account', since: @since.to_date.iso8601, until: (@before - 1.second).to_date.iso8601,
      metrics: series, time_zone: @time_zone }
  end

  # data_from and data_to name the first and last periods with any activity, so the agent hears when the data starts
  # after or ends before the range asked about. An average is active by its events, since a measured average can be zero.
  def metric_series(metric, period, type, id)
    builder = V2::Reports::Conversations::ReportBuilder.new(@account, params.merge(type: type, id: id, metric: metric, group_by: period))
    points = builder.timeseries.map { |point| timeseries_point(point, period, metric) }
    active = points.select { |point| point.fetch(:events, point[:value]).to_f.positive? }
    { metric: metric, points: points, total_or_average: overall(builder, metric),
      data_from: active.first&.dig(:period), data_to: active.last&.dig(:period) }
  end

  # One row per agent, inbox, team or label with the metric in the range, each with the metric per period. A row is kept
  # when it has the metric, so an agent who only replied to older conversations is listed for the messages sent. The note
  # says when rows were left unchecked or unlisted, so the answer can state its coverage.
  def breakdown(metrics, period, dimension)
    raise ArgumentError, 'each takes one metric' if metrics.size > 1

    metric = metrics.first
    candidates = breakdown_candidates(metric, dimension)
    rows = candidates.first(MAX_CHECKED).filter_map do |row|
      series = metric_series(metric, period, dimension, row[:id]).except(:metric)
      { name: row[:name], id: row[:id], **series } if series[:data_from]
    end
    # Averages rank by how many events they average.
    rows = rows.sort_by { |row| -row[:points].sum { |point| point.fetch(:events, point[:value]) } }
    { metric: metric, by: period, each: dimension, rows: rows.first(MAX_EACH),
      note: coverage_note(candidates.size, rows.size, dimension), time_zone: @time_zone }.compact
  end

  # Messages sent are ranked by each one's messages sent, because an agent can send many replies on few conversations.
  # Other metrics are ranked by conversations, as the summary lists them.
  def breakdown_candidates(metric, dimension)
    return summary_rows(dimension) unless metric == 'outgoing_messages_count'

    rows = V2::Reports::OutgoingMessagesCountBuilder.new(@account, params.merge(group_by: dimension)).build
    rows.select { |row| row[:id] }.sort_by { |row| -row[:outgoing_messages_count] }
  end

  def coverage_note(checkable, listed, dimension)
    notes = [("Checked the #{MAX_CHECKED} busiest of #{checkable} #{dimension.pluralize}." if checkable > MAX_CHECKED),
             ("Showing the #{MAX_EACH} busiest of #{listed}." if listed > MAX_EACH)]
    notes.compact.join(' ').presence
  end

  # The summary lists counts and average times; it can chart its two counts. The agents, inboxes, teams or labels with no
  # activity are counted, so an answer about the others is a number, not a guess.
  def summary(dimension, metrics, order)
    if @chart && !metrics.intersect?(SUMMARY_COUNTS.keys)
      raise ArgumentError, "A chart by #{dimension} needs conversations_count or resolutions_count in metrics"
    end

    all = summary_rows(dimension, (metrics & SUMMARY_COLUMNS.keys).first || 'conversations_count', order)
    rows = active(all)
    result = { by: dimension, rows: rows, without_activity: all.size - rows.size, time_zone: @time_zone }
    missing = metrics - SUMMARY_COLUMNS.keys
    if missing.any?
      result[:note] = "The summary has no #{missing.join(', ')}. For them per #{dimension}, call get_report by day, week, month or " \
                      "year with each set to #{dimension}."
    end
    return result unless @chart

    result.merge(Captain::Copilot::Chart.for(@tool_call, (metrics & SUMMARY_COUNTS.keys).map { |metric| summary_chart(dimension, metric, rows) }))
  end

  # Every agent, inbox, team or label the builder lists, ranked by the metric from the highest value, or from the lowest
  # when order is lowest. Those without a value for it come last either way.
  def summary_rows(dimension, ranked_by = 'conversations_count', order = 'highest')
    builder = SUMMARY_BUILDERS.fetch(dimension) do
      raise ArgumentError, "by must be one of: #{([RANGE] + PERIODS + SUMMARY_BUILDERS.keys).join(', ')}"
    end
    names = dimension_names(dimension)
    rows = builder.new(account: @account, params: params.merge(type: dimension.to_sym)).build
    rows = rows.map { |row| row.merge(row.slice(*LABEL_TIMES).transform_values(&:nonzero?)) } if dimension == 'label'
    column = SUMMARY_COLUMNS.fetch(ranked_by)
    rows.sort_by { |row| rank_key(row[column], order) }.map { |row| summary_row(row, names) }
  end

  def rank_key(value, order)
    return [1, 0] if value.nil?

    [0, order == 'lowest' ? value.to_f : -value.to_f]
  end

  # The rows with conversations, resolutions or response times in the range. Times come from replies sent in the range,
  # so an agent who only replied to older conversations has them without either count.
  def active(rows)
    rows.select { |row| row[:conversations].positive? || row[:resolved].positive? || row[:avg_first_response_time] || row[:avg_reply_time] }
  end

  # The time series builders bucket periods in the zone name; the offset is for builders that take only an offset.
  def params
    offset = ActiveSupport::TimeZone[@time_zone].now.utc_offset / 3600.0
    { since: @since, until: @before, business_hours: @business_hours, timezone: @time_zone, timezone_offset: offset }
  end

  def report_kind(by, filters)
    return :range if by == RANGE
    return :summary unless PERIODS.include?(by)

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

    label.merge(value: point[:value]&.to_f&.round, duration: (duration(point[:value]) if point[:count].positive?), events: point[:count])
  end

  # The total the reports pages show. Adding up the periods would count a conversation twice when a metric counts each
  # conversation once, such as bot handoffs.
  def overall(builder, metric)
    value = builder.aggregate_value
    AVERAGES.include?(metric) ? duration(value) : value
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
    { title: "#{name}#{" for #{subject}" if subject} by #{period}, #{Captain::Copilot::Chart.range_text(@since, @before)}", label: name,
      points: entry[:points].map { |point| point[:period].first(10) }.zip(values) }
  end

  def summary_chart(dimension, metric, rows)
    name = METRIC_NAMES.fetch(metric)
    { title: "#{name} by #{dimension}, #{Captain::Copilot::Chart.range_text(@since, @before)}", label: name,
      points: rows.map { |row| [row[:name], row[SUMMARY_COUNTS[metric]]] } }
  end
end
