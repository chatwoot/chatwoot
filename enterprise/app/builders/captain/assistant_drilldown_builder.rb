# Lists the underlying records behind a single Captain assistant stat card, so a
# viewer can drill from an aggregate (e.g. "auto-resolution 42%") into the exact
# conversations that produced it.
#
# The window is resolved by Captain::AssistantStatsWindow from the same `range`
# and `timezone_offset` the stat card used, so the drilldown covers precisely the
# rows the card counted. Records are serialized with the shared reports drilldown
# serializer, so the existing frontend drilldown drawer/card can render them.
class Captain::AssistantDrilldownBuilder
  ASSISTANT_SENDER_TYPE = 'Captain::Assistant'.freeze
  RESOLVED_EVENT_NAMES = Captain::AssistantStatsBuilder::RESOLVED_EVENT_NAMES
  HANDOFF_EVENT_NAMES = Captain::AssistantStatsBuilder::HANDOFF_EVENT_NAMES

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
    case metric
    when 'conversations_handled' then handled_conversations
    when 'auto_resolution_rate' then conversations_for(resolved_events.select(:conversation_id))
    when 'handoff_rate' then event_conversations(HANDOFF_EVENT_NAMES)
    when 'reopen_rate' then reopened_conversations
    else
      raise ArgumentError, "Unsupported assistant drilldown metric: #{metric}"
    end
  end

  # Messages the assistant authored in the window; the cohort every metric derives from.
  def handled_messages
    account.messages.where(sender_type: ASSISTANT_SENDER_TYPE, sender_id: assistant.id, created_at: range)
  end

  def handled_conversation_ids
    handled_messages.select(:conversation_id)
  end

  def handled_conversations
    conversations_for(handled_conversation_ids)
  end

  # Conversations in the handled cohort that recorded one of the given reporting
  # events in the window (resolved or handed-off).
  def event_conversations(event_names)
    ids = account.reporting_events
                 .where(name: event_names, created_at: range, conversation_id: handled_conversation_ids)
                 .select(:conversation_id)
    conversations_for(ids)
  end

  # Captain resolves in the window, excluding bot-resolved rows whose conversation
  # was also handed off, mirroring AssistantStatsBuilder#resolved_clause so the
  # drilldown lists exactly the conversations the auto-resolution card counted.
  def resolved_events
    handoff_ids = account.reporting_events.where(name: HANDOFF_EVENT_NAMES, created_at: range).select(:conversation_id)
    account.reporting_events
           .where(name: RESOLVED_EVENT_NAMES, created_at: range, conversation_id: handled_conversation_ids)
           .where("NOT (name = ? AND conversation_id IN (#{handoff_ids.to_sql}))",
                  Captain::AssistantStatsBuilder::BOT_RESOLVED_EVENT_NAME)
  end

  # Auto-resolved conversations that reopened at/after their Captain resolve,
  # mirroring AssistantStatsBuilder#reopen_rate's numerator cohort.
  def reopened_conversations
    ids = account.reporting_events
                 .where(name: 'conversation_opened')
                 .where('reporting_events.value > 0')
                 .where('reporting_events.event_end_time <= ?', range.last)
                 .joins("INNER JOIN (#{resolved_events.to_sql}) resolves " \
                        'ON resolves.conversation_id = reporting_events.conversation_id ' \
                        'AND reporting_events.event_end_time >= resolves.event_end_time')
                 .select('reporting_events.conversation_id')
    conversations_for(ids)
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
