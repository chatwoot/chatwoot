class V2::Reports::Timeseries::AverageReportBuilder < V2::Reports::Timeseries::BaseTimeseriesBuilder
  def timeseries
    grouped_average_time = reporting_events.average(average_value_key)
    grouped_event_count = reporting_events.count
    grouped_average_time.each_with_object([]) do |element, arr|
      event_date, average_time = element
      arr << {
        value: average_time,
        timestamp: event_date.in_time_zone(timezone).to_i,
        count: grouped_event_count[event_date]
      }
    end
  end

  def aggregate_value
    object_scope.average(average_value_key)
  end

  private

  def event_name
    metric_to_event_name = {
      avg_first_response_time: :first_response,
      avg_resolution_time: :conversation_resolved,
      reply_time: :reply_time
    }
    metric_to_event_name[params[:metric].to_sym]
  end


  def object_scope
    # Fix: Convert `params[:type]` to string for comparison
    if params[:type].to_s == 'label' && params[:id].present?
      Rails.logger.debug "Processing for label type with IDs: #{params[:id]}"
      
      # Split the label IDs and fetch the corresponding label names
      label_ids = params[:id].split(',')
      label_names = account.labels.where(id: label_ids).pluck(:title)
      Rails.logger.debug "Label names fetched: #{label_names}"
  
      # Ensure that conversations contain ALL specified labels (AND relationship)
      conversations = Conversation.where(
        label_names.map { |name| "cached_label_list ILIKE ?" }.join(' AND '),
        *label_names.map { |name| "%#{name}%" }
      )
      Rails.logger.debug "Conversations with matching labels: #{conversations.pluck(:id)}"
  
      # Fetch reporting events for the conversations with matching labels
      reporting_event_query = ReportingEvent.where(conversation_id: conversations.pluck(:id))
                                            .where(account_id: account.id)
                                            .where(name: event_name)
                                            .where(created_at: range)
  
      # Log the generated SQL query for debugging purposes
      Rails.logger.debug "Generated SQL Query: #{reporting_event_query.to_sql}"
  
      return reporting_event_query
    else
      Rails.logger.debug "Processing for non-label type: #{params[:type]}"
      
      if scope.respond_to?(:reporting_events)
        # Generate the query for reporting events when the scope is not a label
        reporting_event_query = scope.reporting_events.where(name: event_name, created_at: range)
        Rails.logger.debug "Generated SQL Query: #{reporting_event_query.to_sql}"
  
        return reporting_event_query
      else
        # Log an error if the scope doesn't have reporting events
        Rails.logger.error "Scope does not have reporting events. Scope Class: #{scope.class.name}, Scope Value: #{scope.inspect}"
        raise NoMethodError, "The selected scope does not have reporting events"
      end
    end
  end
  
  
  

  def reporting_events
    @grouped_values = object_scope.group_by_period(
      group_by,
      :created_at,
      default_value: 0,
      range: range,
      permit: %w[day week month year hour],
      time_zone: timezone
    )
  end

  def average_value_key
    @average_value_key ||= params[:business_hours].present? ? :value_in_business_hours : :value
  end
end
