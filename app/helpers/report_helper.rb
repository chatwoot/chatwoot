module ReportHelper
  private

  def scope
    case params[:type]
    when :account
      account
    when :inbox
      inbox
    when :agent
      user
    when :label
      label
    when :team
      team
    end
  end

  def custom_filter(collection)
    return collection if collection.blank?

    case collection.model_name.name
    when 'Conversation'
      filter_conversations(collection)
    when 'Message'
      filter_messages(collection)
    when 'ReportingEvent'
      filter_reporting_events(collection)
    else
      collection
    end
  end

  def get_filter(key)
    filter = params.dig(:custom_filter, key)
    return [] unless filter.present?

    filter.to_unsafe_h.values
  end

  def selected_label
    get_filter(:selected_label)
  end

  def selected_team
    get_filter(:selected_team)
  end

  def selected_inbox
    get_filter(:selected_inbox)
  end

  def selected_rating
    get_filter(:selected_rating)
  end

  def filter_conversations(collection)
    collection = collection.where(cached_label_list: selected_label) if selected_label.present?

    collection = collection.where(team_id: selected_team) if selected_team.present?

    collection = collection.where(inbox_id: selected_inbox) if selected_inbox.present?

    if selected_rating.present?
      collection = collection.joins(:csat_survey_responses).where(csat_survey_responses: { rating: selected_rating }).distinct
    end

    collection
  end

  def filter_messages(collection)
    collection = collection.joins(:conversation).where(conversations: { cached_label_list: selected_label }) if selected_label.present?

    collection = collection.joins(:conversation).where(conversations: { team_id: selected_team }) if selected_team.present?

    collection = collection.where(inbox_id: selected_inbox) if selected_inbox.present?

    if selected_rating.present?
      collection = collection.joins(conversation: :csat_survey_responses).where(csat_survey_responses: { rating: selected_rating }).distinct
    end

    collection
  end

  def filter_reporting_events(collection)
    collection = collection.joins(:conversation).where(conversations: { cached_label_list: selected_label }) if selected_label.present?

    collection = collection.joins(:conversation).where(conversations: { team_id: selected_team }) if selected_team.present?

    collection = collection.where(inbox_id: selected_inbox) if selected_inbox.present?

    if selected_rating.present?
      collection = collection.joins(conversation: :csat_survey_responses).where(csat_survey_responses: { rating: selected_rating }).distinct
    end

    collection
  end

  def conversations_count
    (get_grouped_values conversations).count
  end

  def incoming_messages_count
    (get_grouped_values incoming_messages).count
  end

  def outgoing_messages_count
    (get_grouped_values outgoing_messages).count
  end

  def resolutions_count
    (get_grouped_values resolutions).count
  end

  def bot_resolutions_count
    (get_grouped_values bot_resolutions).count
  end

  def bot_handoffs_count
    (get_grouped_values bot_handoffs).count
  end

  def conversations
    custom_filter(scope.conversations).where(account_id: account.id, created_at: range)
  end

  def incoming_messages
    custom_filter(scope.messages).where(account_id: account.id, created_at: range).incoming.unscope(:order)
  end

  def outgoing_messages
    custom_filter(scope.messages).where(account_id: account.id, created_at: range).outgoing.unscope(:order)
  end

  def resolutions
    custom_filter(scope.reporting_events).joins(:conversation).select(:conversation_id).where(account_id: account.id, name: :conversation_resolved,
                                                                                              conversations: { status: :resolved }, created_at: range).distinct
  end

  def bot_resolutions
    custom_filter(scope.reporting_events).joins(:conversation).select(:conversation_id).where(account_id: account.id, name: :conversation_bot_resolved,
                                                                                              conversations: { status: :resolved }, created_at: range).distinct
  end

  def bot_handoffs
    custom_filter(scope.reporting_events).joins(:conversation).select(:conversation_id).where(account_id: account.id, name: :conversation_bot_handoff,
                                                                                              created_at: range).distinct
  end

  def avg_first_response_time
    grouped_reporting_events = (get_grouped_values custom_filter(scope.reporting_events).where(name: 'first_response', account_id: account.id))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def reply_time
    grouped_reporting_events = (get_grouped_values custom_filter(scope.reporting_events).where(name: 'reply_time', account_id: account.id))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def avg_resolution_time
    grouped_reporting_events = (get_grouped_values custom_filter(scope.reporting_events).where(name: 'conversation_resolved', account_id: account.id))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def avg_resolution_time_summary
    reporting_events = custom_filter(scope.reporting_events)
                       .where(name: 'conversation_resolved', account_id: account.id, created_at: range)
    avg_rt = if params[:business_hours].present?
               reporting_events.average(:value_in_business_hours)
             else
               reporting_events.average(:value)
             end

    return 0 if avg_rt.blank?

    avg_rt
  end

  def reply_time_summary
    reporting_events = custom_filter(scope.reporting_events)
                       .where(name: 'reply_time', account_id: account.id, created_at: range)
    reply_time = params[:business_hours] ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if reply_time.blank?

    reply_time
  end

  def avg_first_response_time_summary
    reporting_events = custom_filter(scope.reporting_events)
                       .where(name: 'first_response', account_id: account.id, created_at: range)
    avg_frt = if params[:business_hours].present?
                reporting_events.average(:value_in_business_hours)
              else
                reporting_events.average(:value)
              end

    return 0 if avg_frt.blank?

    avg_frt
  end
end
