class V2::Reports::Timeseries::CountReportBuilder < V2::Reports::Timeseries::BaseTimeseriesBuilder
  def timeseries
    grouped_count.each_with_object([]) do |element, arr|
      event_date, event_count = element

      # The `event_date` is in Date format (without time), such as "Wed, 15 May 2024".
      # We need a timestamp for the start of the day. However, we can't use `event_date.to_time.to_i`
      # because it converts the date to 12:00 AM server timezone.
      # The desired output should be 12:00 AM in the specified timezone.
      arr << { value: event_count, timestamp: event_date.in_time_zone(timezone).to_i }
    end
  end

  def aggregate_value
    object_scope.count
  end

  private

  def metric
    @metric ||= params[:metric]
  end

  def object_scope
    send("scope_for_#{metric}")
  end

  def scope_for_conversations_count
    if params[:type].to_s == 'label' && params[:id].present?
      # Split the IDs from the params[:id] string and fetch the corresponding label names
      label_ids = params[:id].split(',')
      label_names = account.labels.where(id: label_ids).pluck(:title) # Assuming the field is 'title'
  
      # Ensure that conversations contain ALL specified labels (AND relationship)
      account.conversations.where(created_at: range)
                           .where(
                             label_names.map { |name| "cached_label_list ILIKE ?" }.join(' AND '),
                             *label_names.map { |name| "%#{name}%" }
                           )
    else
      # Default behavior when no labels are involved
      account.conversations.where(created_at: range)
    end
  end
  

  def scope_for_incoming_messages_count
    if params[:type].to_s == 'label' && params[:id].present?
      # Split the label IDs from params[:id]
      label_ids = params[:id].split(',')
      # Fetch label names associated with the label IDs
      label_names = account.labels.where(id: label_ids).pluck(:title) # Assuming the field is 'title'
  
      # Ensure that conversations contain ALL specified labels (AND relationship)
      Message.joins(:conversation)
             .where(conversations: { account_id: account.id, created_at: range })
             .where(
               label_names.map { |name| "conversations.cached_label_list ILIKE ?" }.join(' AND '),
               *label_names.map { |name| "%#{name}%" }
             )
             .incoming
             .unscope(:order)
    else
      # Fallback to default scope
      Message.joins(:conversation)
             .where(conversations: { account_id: account.id, created_at: range })
             .incoming
             .unscope(:order)
    end
  end
  

  def scope_for_outgoing_messages_count
    if params[:type].to_s == 'label' && params[:id].present?
      # Handle the case where labels are passed in
      label_ids = params[:id].split(',')
      label_names = account.labels.where(id: label_ids).pluck(:title)
  
      # Ensure conversations contain ALL specified labels (AND relationship)
      conversations = Conversation.where(
        label_names.map { |name| "cached_label_list ILIKE ?" }.join(' AND '),
        *label_names.map { |name| "%#{name}%" }
      )
  
      # Fetch outgoing messages for those conversations
      Message.where(conversation_id: conversations.pluck(:id))
             .where(account_id: account.id, created_at: range)
             .outgoing.unscope(:order)
    else
      # Regular case when it's not label type
      scope.messages.where(account_id: account.id, created_at: range).outgoing.unscope(:order)
    end
  end
  



  def scope_for_resolutions_count
    if params[:type].to_s == 'label' && params[:id].present?
      # Handling the case where labels are passed in
      label_ids = params[:id].split(',')
      label_names = account.labels.where(id: label_ids).pluck(:title)
  
      # Ensure that conversations contain ALL specified labels
      conversations = Conversation.where(
        label_names.map { |name| "cached_label_list ILIKE ?" }.join(' AND '),
        *label_names.map { |name| "%#{name}%" }
      )
  
      # Fetch reporting events for those conversations
      ReportingEvent.joins(:conversation)
                    .where(conversation_id: conversations.pluck(:id))
                    .where(name: :conversation_resolved, conversations: { status: :resolved })
                    .where(created_at: range)
                    .distinct
    else
      # Handle the regular case for other types (e.g., account, inbox)
      scope.reporting_events.joins(:conversation)
                            .where(name: :conversation_resolved, conversations: { status: :resolved })
                            .where(created_at: range)
                            .distinct
    end
  end
  
  

  def scope_for_bot_resolutions_count
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(
      name: :conversation_bot_resolved,
      conversations: { status: :resolved }, created_at: range
    ).distinct
  end

  def scope_for_bot_handoffs_count
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(
      name: :conversation_bot_handoff,
      created_at: range
    ).distinct
  end

  def grouped_count
    @grouped_values = object_scope.group_by_period(
      group_by,
      :created_at,
      default_value: 0,
      range: range,
      permit: %w[day week month year hour],
      time_zone: timezone
    ).count
  end
end
