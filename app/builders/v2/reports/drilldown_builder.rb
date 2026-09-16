class V2::Reports::DrilldownBuilder
  include DateRangeHelper
  include TimezoneHelper

  DEFAULT_GROUP_BY = 'day'.freeze
  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  SUPPORTED_GROUP_BY = %w[hour day week month year].freeze
  SUPPORTED_DIMENSION_TYPES = %w[account inbox agent label team].freeze
  MESSAGE_METRICS = {
    'incoming_messages_count' => :incoming,
    'outgoing_messages_count' => :outgoing
  }.freeze
  MESSAGE_EVENT_METRICS = %w[avg_first_response_time reply_time].freeze

  pattr_initialize :account, :params

  def self.supported_dimension_type?(type) = SUPPORTED_DIMENSION_TYPES.include?((type.presence || 'account').to_s)

  def build
    records = paginated_records.to_a
    { meta: meta, payload: records.map { |record| record_serializer(records).serialize(record) } }
  end

  private

  def meta
    {
      metric: metric,
      record_type: record_type,
      bucket: {
        since: bucket_range.begin.to_i,
        until: bucket_range.end.to_i
      },
      current_page: current_page,
      per_page: per_page,
      total_count: paginated_records.total_count,
      conversation_count: conversation_count
    }
  end

  def conversation_count
    return paginated_records.total_count if conversation_metric?

    drilldown_scope.except(:includes).reorder(nil).distinct.count(:conversation_id)
  end

  def paginated_records
    @paginated_records ||= drilldown_scope.page(current_page).per(per_page)
  end

  def drilldown_scope
    if message_metric?
      message_scope
    elsif conversation_metric?
      conversation_scope
    else
      reporting_event_scope
    end
  end

  def message_scope
    scope.messages
         .where(account_id: account.id, created_at: bucket_range)
         .public_send(MESSAGE_METRICS.fetch(metric))
         .includes(:sender, conversation: [:assignee, :contact, :inbox])
         .reorder(created_at: :desc)
  end

  def conversation_scope
    scope.conversations
         .where(account_id: account.id, created_at: bucket_range)
         .includes(:assignee, :contact, :inbox)
         .order(created_at: :desc)
  end

  def reporting_event_scope
    events = scope.reporting_events
                  .where(account_id: account.id, name: raw_event_name, created_at: bucket_range)
                  .includes(:user, :inbox, conversation: [:assignee, :contact, :inbox])
                  .order(created_at: :desc)

    if raw_count_strategy == :exclude_bot_handoffs
      events = events.where.not(conversation_id: bot_handoff_conversation_ids_subquery)
    elsif raw_count_strategy == :distinct_conversation
      events = events.where(id: distinct_conversation_event_ids(events))
    end

    events
  end

  def bot_handoff_conversation_ids_subquery
    scope.reporting_events
         .where(account_id: account.id, name: :conversation_bot_handoff, created_at: range)
         .where.not(conversation_id: nil)
         .select(:conversation_id)
  end

  def distinct_conversation_event_ids(events)
    events.reorder(nil)
          .where.not(conversation_id: nil)
          .select('MAX(reporting_events.id)')
          .group(:conversation_id)
  end

  def record_serializer(records)
    @record_serializer ||= V2::Reports::DrilldownRecordSerializer.new(
      account,
      metric,
      use_business_hours?,
      records
    )
  end

  def bucket_range
    @bucket_range ||= begin
      bucket_start = Time.zone.at(params[:bucket_timestamp].to_i).in_time_zone(timezone)
      bucket_end = bucket_end_for(bucket_start)
      requested_start = Time.zone.at(params[:since].to_i)
      requested_end = Time.zone.at(params[:until].to_i)

      [bucket_start, requested_start].max...[bucket_end, requested_end].min
    end
  end

  def bucket_end_for(bucket_start)
    {
      'hour' => bucket_start + 1.hour,
      'day' => bucket_start + 1.day,
      'week' => bucket_start + 1.week,
      'month' => bucket_start + 1.month,
      'year' => bucket_start + 1.year
    }.fetch(group_by)
  end

  def scope
    case dimension_type
    when 'account' then account
    when 'inbox' then inbox
    when 'agent' then user
    when 'label' then label
    when 'team' then team
    else
      raise ArgumentError, "Unsupported drilldown dimension type: #{dimension_type}"
    end
  end

  def inbox = @inbox ||= account.inboxes.find(params[:id])

  def user = @user ||= account.users.find(params[:id])

  def label = @label ||= account.labels.find(params[:id])

  def team = @team ||= account.teams.find(params[:id])

  def metric
    params[:metric].to_s
  end

  def report_metric
    @report_metric ||= Reports::ReportMetricRegistry.fetch(metric)
  end

  def raw_event_name
    report_metric&.raw_event_name
  end

  def raw_count_strategy
    report_metric&.raw_count_strategy
  end

  def record_type
    return 'message' if message_metric? || MESSAGE_EVENT_METRICS.include?(metric)

    'conversation'
  end

  def message_metric?
    MESSAGE_METRICS.key?(metric)
  end

  def conversation_metric?
    metric == 'conversations_count'
  end

  def dimension_type
    (params[:type].presence || 'account').to_s
  end

  def group_by
    @group_by ||= SUPPORTED_GROUP_BY.include?(params[:group_by].to_s) ? params[:group_by].to_s : DEFAULT_GROUP_BY
  end

  def timezone
    @timezone ||= timezone_name_from_offset(params[:timezone_offset])
  end

  def current_page
    [params[:page].to_i, DEFAULT_PAGE].max
  end

  def per_page
    requested_per_page = params[:per_page].to_i
    requested_per_page = DEFAULT_PER_PAGE if requested_per_page <= 0

    [requested_per_page, MAX_PER_PAGE].min
  end

  def use_business_hours?
    ActiveModel::Type::Boolean.new.cast(params[:business_hours])
  end
end
