class Captain::AssistantOverviewDrilldownBuilder
  include Captain::AssistantOutcomeClassification

  SUPPORTED_METRICS = %w[
    conversations_handled auto_resolution_rate handoff_rate reopen_rate durable_resolution_rate
  ].freeze
  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  pattr_initialize :assistant, :params

  def self.supported_metric?(metric) = SUPPORTED_METRICS.include?(metric.to_s)

  def build
    records = paginated_outcomes.to_a
    serializer = V2::Reports::DrilldownRecordSerializer.new(assistant.account, params[:metric], false, records.map(&:conversation))

    {
      meta: { total_count: paginated_outcomes.total_count, current_page: current_page, per_page: per_page },
      payload: records.map do |outcome|
        serializer.serialize(outcome.conversation).merge(
          episode_id: outcome.id, episode_started_at: outcome.started_at.to_i
        )
      end
    }
  end

  private

  def paginated_outcomes
    window = Captain::AssistantStatsWindow.new(params[:range], params[:timezone_offset]).current
    @paginated_outcomes ||= assistant.account.conversation_outcomes
                                     .where(assistant_id: assistant.id, started_at: window)
                                     .where(metric_predicate)
                                     .includes(conversation: [:contact, :inbox, :assignee])
                                     .order(started_at: :desc, id: :desc)
                                     .page(current_page).per(per_page)
  end

  def metric_predicate
    table = ConversationOutcome.arel_table
    case params[:metric].to_s
    when 'conversations_handled' then involved(table)
    when 'auto_resolution_rate' then autonomous(table)
    when 'handoff_rate' then handoff(table)
    when 'reopen_rate' then reopened_autonomous(table)
    when 'durable_resolution_rate'
      autonomous(table).and(table[:resolved_at].lteq(Time.current - DURABLE_RESOLUTION_WINDOW)).and(durable(table))
    else
      raise ArgumentError, "Unsupported overview drilldown metric: #{params[:metric]}"
    end
  end

  def current_page = [params[:page].to_i, DEFAULT_PAGE].max

  def per_page
    requested = params[:per_page].to_i
    requested = DEFAULT_PER_PAGE if requested <= 0
    [requested, MAX_PER_PAGE].min
  end
end
