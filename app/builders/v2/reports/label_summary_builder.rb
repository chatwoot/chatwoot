class V2::Reports::LabelSummaryBuilder < V2::Reports::BaseSummaryBuilder
  attr_reader :account, :params

  # rubocop:disable Lint/MissingSuper
  # the parent class has no initialize
  def initialize(account:, params:)
    @account = account
    @params = params

    timezone_offset = (params[:timezone_offset] || 0).to_f
    @timezone = ActiveSupport::TimeZone[timezone_offset]&.name
  end
  # rubocop:enable Lint/MissingSuper

  def build
    labels = account.labels.to_a
    return [] if labels.empty?

    report_data = collect_report_data
    labels.map { |label| build_label_report(label, report_data) }
  end

  private

  def collect_report_data
    conversation_filter = build_conversation_filter
    use_business_hours = use_business_hours?

    {
      conversation_counts: fetch_conversation_counts(conversation_filter),
      resolved_counts: fetch_resolved_counts,
      resolution_metrics: fetch_metrics(conversation_filter, 'conversation_resolved', use_business_hours),
      first_response_metrics: fetch_metrics(conversation_filter, 'first_response', use_business_hours),
      reply_metrics: fetch_metrics(conversation_filter, 'reply_time', use_business_hours)
    }
  end

  def build_label_report(label, report_data)
    {
      id: label.id,
      name: label.title,
      conversations_count: report_data[:conversation_counts][label.title] || 0,
      avg_resolution_time: report_data[:resolution_metrics][label.title] || 0,
      avg_first_response_time: report_data[:first_response_metrics][label.title] || 0,
      avg_reply_time: report_data[:reply_metrics][label.title] || 0,
      resolved_conversations_count: report_data[:resolved_counts][label.title] || 0
    }
  end

  def use_business_hours?
    ActiveModel::Type::Boolean.new.cast(params[:business_hours])
  end

  def build_conversation_filter
    conversation_filter = { account_id: account.id }
    conversation_filter[:created_at] = range if range.present?

    conversation_filter
  end

  def fetch_conversation_counts(conversation_filter)
    fetch_counts(conversation_filter)
  end

  def fetch_resolved_counts
    # Count resolution events, not conversations currently in resolved status
    # Filter by reporting_event.created_at, not conversation.created_at
    reporting_event_filter = { name: 'conversation_resolved', account_id: account.id }
    reporting_event_filter[:created_at] = range if range.present?

    ReportingEvent
      .joins(conversation: { taggings: :tag })
      .where(
        reporting_event_filter.merge(
          taggings: { taggable_type: 'Conversation', context: 'labels' }
        )
      )
      .group('tags.name')
      .count
  end

  def fetch_counts(conversation_filter)
    ActsAsTaggableOn::Tagging
      .joins('INNER JOIN conversations ON taggings.taggable_id = conversations.id')
      .joins('INNER JOIN tags ON taggings.tag_id = tags.id')
      .where(
        taggable_type: 'Conversation',
        context: 'labels',
        conversations: conversation_filter
      )
      .select('tags.name, COUNT(taggings.*) AS count')
      .group('tags.name')
      .each_with_object({}) { |record, hash| hash[record.name] = record.count }
  end

  def fetch_metrics(conversation_filter, event_name, use_business_hours)
    ReportingEvent
      .joins(conversation: { taggings: :tag })
      .where(
        conversations: conversation_filter,
        name: event_name,
        taggings: { taggable_type: 'Conversation', context: 'labels' }
      )
      .group('tags.name')
      .order('tags.name')
      .select(
        'tags.name',
        use_business_hours ? 'AVG(reporting_events.value_in_business_hours) as avg_value' : 'AVG(reporting_events.value) as avg_value'
      )
      .each_with_object({}) { |record, hash| hash[record.name] = record.avg_value.to_f }
  end
end
