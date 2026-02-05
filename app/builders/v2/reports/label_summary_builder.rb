class V2::Reports::LabelSummaryBuilder < V2::Reports::BaseSummaryBuilder
  attr_reader :account, :params

  def initialize(account:, params:)
    super()
    @account = account
    @params = params
    @timezone = 'UTC'
  end

  def build
    metrics = collect_metrics
    build_label_reports(metrics)
  end

  private

  def collect_metrics
    {
      conversation_counts: fetch_conversation_counts,
      resolved_counts: fetch_event_counts('conversation_resolved'),
      resolution_times: fetch_event_averages('conversation_resolved'),
      first_response_times: fetch_event_averages('first_response'),
      reply_times: fetch_event_averages('reply_time')
    }
  end

  def build_label_reports(metrics)
    labels = fetch_labels_to_report
    return [] if labels.empty?

    labels.map { |label| build_single_label_report(label, metrics) }
  end

  def fetch_conversation_counts
    base_taggings_scope
      .select('tags.name, COUNT(DISTINCT taggings.taggable_id) as count').group('tags.name')
      .index_by(&:name).transform_values(&:count)
  end

  def fetch_event_counts(event_name)
    base_events_scope(event_name).group('tags.name').count('DISTINCT reporting_events.id')
  end

  def fetch_event_averages(event_name)
    value_column = use_business_hours? ? 'value_in_business_hours' : 'value'
    base_events_scope(event_name).group('tags.name').average("reporting_events.#{value_column}").transform_values(&:to_f)
  end

  def base_taggings_scope
    scope = ActsAsTaggableOn::Tagging
            .joins('INNER JOIN conversations ON taggings.taggable_id = conversations.id')
            .joins('INNER JOIN tags ON taggings.tag_id = tags.id')
            .where(taggable_type: 'Conversation', context: 'labels', conversations: base_conversation_filters)
    scope = apply_label_filter_to_taggings(scope) if params[:label_ids].present?
    scope
  end

  def base_events_scope(event_name)
    scope = ReportingEvent
            .joins(conversation: { taggings: :tag })
            .where(name: event_name, conversations: base_conversation_filters, taggings: { taggable_type: 'Conversation', context: 'labels' })
    scope = apply_reporting_event_filters(scope)
    scope = scope.filter_by_label_ids(params[:label_ids], account.id) if params[:label_ids].present?
    scope
  end

  def base_conversation_filters
    base_filters.merge(optional_conversation_filters)
  end

  def base_filters
    { account_id: account.id, created_at: range }
  end

  def optional_conversation_filters
    {}.tap do |filters|
      filters[:assignee_id] = params[:user_ids].reject(&:blank?) if params[:user_ids].present?
      filters[:inbox_id] = params[:inbox_ids].reject(&:blank?) if params[:inbox_ids].present?
      filters[:team_id] = params[:team_ids].reject(&:blank?) if params[:team_ids].present?
    end
  end

  def apply_reporting_event_filters(scope)
    scope = scope.where(user_id: params[:user_ids].reject(&:blank?)) if params[:user_ids].present?
    scope = scope.where(inbox_id: params[:inbox_ids].reject(&:blank?)) if params[:inbox_ids].present?
    scope
  end

  def apply_label_filter_to_taggings(scope)
    tag_ids = ReportingEvent.tag_ids_for_labels(params[:label_ids].reject(&:blank?), account.id)
    return scope.none if tag_ids.empty?

    scope.where(tags: { id: tag_ids })
  end

  def fetch_labels_to_report
    if params[:label_ids].present? && params[:label_ids].reject(&:blank?).any?
      account.labels.where(id: params[:label_ids].reject(&:blank?)).to_a
    else
      label_names = extract_unique_label_names_from_metrics
      return [] if label_names.empty?

      account.labels.where(title: label_names).to_a
    end
  end

  def extract_unique_label_names_from_metrics
    @metrics ||= collect_metrics
    @metrics.values.flat_map(&:keys).compact.uniq
  end

  def build_single_label_report(label, metrics)
    {
      id: label.id,
      name: label.title,
      conversations_count: metrics[:conversation_counts][label.title] || 0,
      resolved_conversations_count: metrics[:resolved_counts][label.title] || 0,
      avg_resolution_time: metrics[:resolution_times][label.title] || 0,
      avg_first_response_time: metrics[:first_response_times][label.title] || 0,
      avg_reply_time: metrics[:reply_times][label.title] || 0
    }
  end

  def use_business_hours?
    ActiveModel::Type::Boolean.new.cast(params[:business_hours])
  end
end
