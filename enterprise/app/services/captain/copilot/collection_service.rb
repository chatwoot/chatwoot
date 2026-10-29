class Captain::Copilot::CollectionService
  # A sample is spread across at most this many matching records.
  SAMPLE_POOL = 100_000

  def initialize(run, tool_call:, token:)
    @run = run
    @tool_call = tool_call
    @token = token
  end

  # counting holds group_by, aggregate and chart.
  def create(resource:, filters:, from: nil, exclude_from: nil, **counting)
    raise ArgumentError, 'filters must be an object' unless filters.is_a?(Hash)

    @selector = Captain::Copilot::Resources.build(resource, account: @run.account, user: @run.user)
    source = saved_set(from)
    excluded = saved_set(exclude_from)
    @filters = @selector.normalize(filters, source: source)
    @as_of = Time.current
    matching = @selector.matching(@filters, as_of: @as_of, source: source, excluded: excluded)
    ids = @filters['sample'] ? sample_ids(matching) : @selector.selected_ids(matching, @filters)
    counted = @filters['newest'] ? matching.where(id: ids) : matching
    collection = persist_collection(resource, ids, source, excluded)
    collection_result(collection, counted).merge(measured(counted, **counting))
  end

  private

  def saved_set(id)
    @run.copilot_thread.saved_set(id) if id
  end

  # Every k-th record in the selection's order, so a sample spreads across the period and is the same each time.
  def sample_ids(matching)
    ids = @selector.selected_ids(matching, @filters, limit: SAMPLE_POOL)
    step = ids.size.fdiv(@filters['sample'])
    step <= 1 ? ids : Array.new(@filters['sample']) { |index| ids[(index * step).floor] }
  end

  # The result names the reporting time zone, so the model never supplies one.
  def measured(counted, group_by: nil, aggregate: nil, chart: false)
    spec = measure_spec(group_by, aggregate)
    return {} unless spec

    range = Range.new(*@selector.date_range(@filters, @as_of), true) if @filters['since']
    result = Captain::Copilot::Aggregation.new(@selector, counted, time_zone: time_zone, date_field: @filters['date_field'], range: range)
                                          .call(**spec)
    measured = { aggregate: result, time_zone: time_zone }
    chart && Array(spec[:group_by]).one? ? measured.merge(chart(result, spec[:group_by].first)) : measured
  end

  def measure_spec(group_by, aggregate)
    return aggregate.to_h.symbolize_keys if aggregate

    { measure: 'count', group_by: [group_by] } if group_by
  end

  def chart(result, field)
    title = "#{result[:measure].humanize} of #{result[:of] || @selector.class::NAME.humanize} by #{field}"
    points = result[:groups].map { |row| [row[:group], row[:value]] }
    Captain::Copilot::Chart.for(@tool_call, [{ title: title, label: result[:measure].humanize, points: points }])
  end

  def time_zone
    @run.account.reporting_timezone.presence || 'UTC'
  end

  def collection_result(collection, counted)
    total = counted.count
    result = collection.summary.merge(collection_id: collection.id, resource: collection.resource, as_of: collection.as_of.iso8601, total: total)
    result[:dates] = @selector.date_span(counted, @filters['date_field']) if total.positive?
    @selector.note ? result.merge(note: @selector.note) : result
  end

  # A selection made from a review of a cut-off collection is cut off too, because the review never read the rest.
  def persist_collection(resource, ids, source, excluded)
    truncated = ids.size > CopilotRun::MAX_SELECTION || (source.is_a?(CopilotRun::Review) && source.selection_truncated?)
    context = { resource: resource, filters: @filters, selected_ids: ids.first(CopilotRun::MAX_SELECTION), as_of: @as_of.iso8601(6),
                selection_truncated: truncated, excluded_run_id: excluded&.id }.compact
    @run.with_lease(@token) do
      CopilotRun::Collection.create_or_find_by!(copilot_tool_call: @tool_call) do |record|
        record.assign_attributes(copilot_thread: @run.copilot_thread, account: @run.account, user: @run.user, source_run: source,
                                 status: :completed, context: context)
      end
    end
  end
end
