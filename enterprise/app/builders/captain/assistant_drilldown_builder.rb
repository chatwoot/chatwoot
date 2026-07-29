# Lists the underlying records behind a single Captain assistant stat card, so a
# viewer can drill from an aggregate (e.g. "auto-resolution 42%") into the exact
# conversations that produced it.
#
# The window is resolved by Captain::AssistantStatsWindow from the same `range`
# and `timezone_offset` the stat card used, and each metric reuses the outcome
# model's classification scopes, so the drilldown covers precisely the rows the
# card counted. Records are serialized with the shared reports drilldown
# serializer, so the existing frontend drilldown drawer/card can render them.
class Captain::AssistantDrilldownBuilder
  SUPPORTED_METRICS = %w[
    conversations_handled auto_resolution_rate handoff_rate reopen_rate
  ].freeze

  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  pattr_initialize :assistant, :params

  def self.supported_metric?(metric) = SUPPORTED_METRICS.include?(metric.to_s)

  def build
    records = paginated_records.to_a
    { meta: meta, payload: records.map { |record| record_serializer(records).serialize(record) } }
  end

  private

  def account = assistant.account

  def window
    @window ||= Captain::AssistantStatsWindow.new(params[:range], params[:timezone_offset])
  end

  def range = window.current

  def meta
    {
      metric: metric,
      current_page: current_page,
      per_page: per_page,
      total_count: paginated_records.total_count,
      conversation_count: paginated_records.total_count,
      range: { since: range.first.to_i, until: range.last.to_i }
    }
  end

  def paginated_records
    @paginated_records ||= drilldown_scope.page(current_page).per(per_page)
  end

  def drilldown_scope
    conversations_for(metric_outcomes.select(:conversation_id))
  end

  # Outcome rows behind the requested stat card, mirroring the event anchors
  # and classifications AssistantStatsBuilder counted for the same window
  # (reply span for handled, resolved_at, handoff_at, last_reopened_at).
  def metric_outcomes
    outcomes = assistant.conversation_outcomes

    case metric
    when 'conversations_handled'
      outcomes.where('first_captain_reply_at <= ? AND last_captain_reply_at >= ?', range.last, range.first)
    when 'auto_resolution_rate'
      outcomes.autonomous_resolved.where(resolved_at: range)
    when 'handoff_rate'
      outcomes.where(handoff_at: range).where.not(handoff_reason_category: 'usage_limit')
    when 'reopen_rate'
      outcomes.autonomous_resolved.where(resolved_at: range, last_reopened_at: range)
    else
      raise ArgumentError, "Unsupported assistant drilldown metric: #{metric}"
    end
  end

  def conversations_for(conversation_ids)
    account.conversations
           .where(id: conversation_ids)
           .includes(:assignee, :contact, :inbox)
           .order(created_at: :desc)
  end

  def record_serializer(records)
    @record_serializer ||= V2::Reports::DrilldownRecordSerializer.new(account, metric, false, records)
  end

  def metric = params[:metric].to_s

  def current_page = [params[:page].to_i, DEFAULT_PAGE].max

  def per_page
    requested_per_page = params[:per_page].to_i
    requested_per_page = DEFAULT_PER_PAGE if requested_per_page <= 0

    [requested_per_page, MAX_PER_PAGE].min
  end
end
