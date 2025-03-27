module Api::V2::Accounts::ReportsHelper
  def generate_agents_report
    reports = V2::Reports::AgentSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :agent)
    ).build

    Current.account.users.map do |agent|
      report = reports.find { |r| r[:id] == agent.id }
      [agent.name] + generate_readable_report_metrics(report)
    end
  end

  def generate_inboxes_report
    reports = V2::Reports::InboxSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :inbox)
    ).build

    Current.account.inboxes.map do |inbox|
      report = reports.find { |r| r[:id] == inbox.id }
      [inbox.name, inbox.channel&.name] + generate_readable_report_metrics(report)
    end
  end

  def generate_teams_report
    reports = V2::Reports::TeamSummaryBuilder.new(
      account: Current.account,
      params: build_params(type: :team)
    ).build

    Current.account.teams.map do |team|
      report = reports.find { |r| r[:id] == team.id }
      [team.name] + generate_readable_report_metrics(report)
    end
  end

  def generate_labels_report
    Current.account.labels.map do |label|
      label_report = report_builder({ type: :label, id: label.id }).short_summary
      [label.title] + generate_readable_report_metrics(label_report)
    end
  end

  # Optimized version that reduces database queries by using batch processing
  # and leveraging database aggregation capabilities
  def generate_labels_report_optimized
    labels = Current.account.labels.to_a
    return [] if labels.empty?

    conversation_filter = { account_id: Current.account.id }
    time_range = nil

    if params[:since].present? && params[:until].present?
      since_datetime = if params[:since].is_a?(DateTime)
                         params[:since]
                       else
                         (if params[:since].is_a?(Time) || params[:since].is_a?(Date)
                            params[:since].to_datetime
                          else
                            DateTime.strptime(params[:since], '%s')
                          end)
                       end

      until_datetime = if params[:until].is_a?(DateTime)
                         params[:until]
                       else
                         (if params[:until].is_a?(Time) || params[:until].is_a?(Date)
                            params[:until].to_datetime
                          else
                            DateTime.strptime(params[:until], '%s')
                          end)
                       end

      time_range = since_datetime...until_datetime
      conversation_filter[:created_at] = time_range
    end

    use_business_hours = ActiveModel::Type::Boolean.new.cast(params[:business_hours])

    # Get conversation counts for all labels in one query
    # SELECT tags.name, COUNT(taggings.*)
    # FROM   taggings
    #        INNER JOIN conversations
    #                ON taggings.taggable_id = conversations.id
    #        INNER JOIN tags
    #                ON taggings.tag_id = tags.id
    # WHERE  taggings.taggable_type = 'Conversation'
    #        AND taggings.context = 'labels'
    #        AND conversations.account_id = 2
    #        AND conversations.created_at >= '2025-03-20 18:30:00'
    #        AND conversations.created_at < '2025-03-27 18:29:59'
    # GROUP BY tags.name
    # ORDER BY tags.name;
    conversation_counts = ActsAsTaggableOn::Tagging
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

    resolved_counts = ActsAsTaggableOn::Tagging
                      .joins('INNER JOIN conversations ON taggings.taggable_id = conversations.id')
                      .joins('INNER JOIN tags ON taggings.tag_id = tags.id')
                      .where(
                        taggable_type: 'Conversation',
                        context: 'labels',
                        conversations: conversation_filter.merge(status: :resolved)
                      )
                      .select('tags.name, COUNT(taggings.*) AS count')
                      .group('tags.name')
                      .each_with_object({}) { |record, hash| hash[record.name] = record.count }

    # Get resolution time metrics
    # SELECT
    #   tags.name,
    #   -- for business hours
    #   -- AVG(reporting_events.value_in_business_hours) as avg_value_raw
    #   AVG(reporting_events.value) as avg_value_raw
    # FROM
    #   reporting_events
    #   INNER JOIN conversations ON reporting_events.conversation_id = conversations.id
    #   INNER JOIN taggings ON taggings.taggable_id = conversations.id
    #   INNER JOIN tags ON taggings.tag_id = tags.id
    # WHERE
    #   conversations.account_id = 2
    #   AND reporting_events.name = 'conversation_resolved'
    #   AND taggings.taggable_type = 'Conversation'
    #   AND taggings.context = 'labels'
    #   AND conversations.created_at >= '2025-03-20 18:30:00'
    #   AND conversations.created_at < '2025-03-27 18:29:59'
    # GROUP BY tags.name
    # ORDER BY tags.name;
    resolution_metrics = ReportingEvent
                         .joins('INNER JOIN conversations ON reporting_events.conversation_id = conversations.id')
                         .joins('INNER JOIN taggings ON taggings.taggable_id = conversations.id')
                         .joins('INNER JOIN tags ON taggings.tag_id = tags.id')
                         .where(
                           conversations: conversation_filter,
                           name: 'conversation_resolved',
                           taggings: { taggable_type: 'Conversation', context: 'labels' }
                         )
                         .group('tags.name')
                         .order('tags.name')
                         .select(
                           'tags.name',
                           use_business_hours ? 'AVG(reporting_events.value_in_business_hours) as avg_value' : 'AVG(reporting_events.value) as avg_value'
                         )
                         .each_with_object({}) { |record, hash| hash[record.name] = record.avg_value.to_f }

    # # Get first response time metrics
    first_response_metrics = ReportingEvent
                             .joins('INNER JOIN conversations ON reporting_events.conversation_id = conversations.id')
                             .joins('INNER JOIN taggings ON taggings.taggable_id = conversations.id')
                             .joins('INNER JOIN tags ON taggings.tag_id = tags.id')
                             .where(
                               conversations: conversation_filter,
                               name: 'first_response',
                               taggings: { taggable_type: 'Conversation', context: 'labels' }
                             )
                             .group('tags.name')
                             .order('tags.name')
                             .select(
                               'tags.name',
                               use_business_hours ? 'AVG(reporting_events.value_in_business_hours) as avg_value' : 'AVG(reporting_events.value) as avg_value'
                             )
                             .each_with_object({}) { |record, hash| hash[record.name] = record.avg_value.to_f }

    # Format the report data in the same structure as the original method
    labels.map do |label|
      label_report = {
        conversations_count: conversation_counts[label.title] || 0,
        avg_resolution_time: resolved_counts[label.title] || 0,
        avg_first_response_time: first_response_metrics[label.title] || 0,
        resolved_conversations_count: conversation_counts[label.title] || 0
      }

      [label.title] + generate_readable_report_metrics(label_report)
    end
  end

  private

  def build_params(base_params)
    base_params.merge(
      {
        since: params[:since],
        until: params[:until],
        business_hours: ActiveModel::Type::Boolean.new.cast(params[:business_hours])
      }
    )
  end

  def report_builder(report_params)
    V2::ReportBuilder.new(Current.account, build_params(report_params))
  end

  def generate_readable_report_metrics(report)
    [
      report[:conversations_count],
      Reports::TimeFormatPresenter.new(report[:avg_first_response_time]).format,
      Reports::TimeFormatPresenter.new(report[:avg_resolution_time]).format,
      Reports::TimeFormatPresenter.new(report[:avg_reply_time]).format,
      report[:resolved_conversations_count]
    ]
  end
end
