# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Layout/LineLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Rails/HelperInstanceVariable
# rubocop:disable Metrics/CyclomaticComplexity
module CustomReportHelper
  include OnlineStatusHelper
  include WorkingHoursHelper
  include BspdAnalyticsHelper

  private

  ### Conversation Statuses Metrics ###
  def new_assigned
    # New conversations assigned in the given time period
    base_query = @account.conversations.where(created_at: @time_range)

    base_query = label_filtered_conversations if @config[:filters][:labels].present?

    # Create a subquery with the latest assignments
    latest_assignments = ConversationAssignment
                         .select('conversation_id, assignee_id, inbox_id, team_id, created_at')
                         .where(account_id: @account.id, conversation_id: base_query.pluck(:id))

    # Wrap it in a subquery to make it countable
    base_query = ConversationAssignment.from("(#{latest_assignments.to_sql}) AS conversation_assignments")

    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info 'New Assigned'
    group_and_count_conversation_assignment(base_query, @config[:group_by])
  end

  def carry_forwarded
    # conversations that were created before the start of the specified time period, but are still not resolved at the start of specified time period
    # not_resolved_conversations_before_time_range = ConversationStatus.from(
    #   "(#{latest_conversation_statuses_before_time_range.to_sql}) AS conversation_statuses"
    # ).where.not(status: :resolved)

    # conversations_without_conversation_status_before_time_range = @account.conversations.where.not(id: ConversationStatus.from(
    #   "(#{latest_conversation_statuses_before_time_range.to_sql}) AS conversation_statuses"
    # ).pluck(:conversation_id)).where('created_at < ?', @time_range.begin).where.not(status: Conversation.statuses[:resolved])

    # TODO: temp fix, need to refine the new query
    base_query = @account.conversations.where('created_at < ?', @time_range.begin).where.not(status: Conversation.statuses[:resolved])

    base_query = label_filtered_conversations.where(id: base_query.pluck(:id)) if @config[:filters][:labels].present?

    latest_assignments = ConversationAssignment
                         .select('DISTINCT ON (conversation_id) *')
                         .where('created_at < ?', @time_range.begin)
                         .where(account_id: @account.id, conversation_id: base_query.pluck(:id))
                         .order('conversation_id, created_at DESC')

    base_query = ConversationAssignment.from("(#{latest_assignments.to_sql}) AS conversation_assignments")

    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info 'Carry Forwarded'
    group_and_count_conversation_assignment(base_query, @config[:group_by])
  end

  def reopened
    # conversations that reverted to an open state from resolved state(any other state doesnt count) during the specified time period.
    resolved_conversations_before_time_range = ConversationStatus.from("(#{latest_conversation_statuses_before_time_range.to_sql}) AS conversation_statuses").where(status: :resolved)

    Rails.logger.info "resolved_conversations_before_time_range: #{resolved_conversations_before_time_range.to_sql}"

    reopened_conversations = first_conversation_statuses.where(conversation_id: resolved_conversations_before_time_range.pluck(:conversation_id)).where(status: :open)

    Rails.logger.info "reopened_conversations: #{reopened_conversations.to_sql}"

    base_query = @account.conversations.where(id: reopened_conversations.pluck(:conversation_id))

    base_query = label_filtered_conversations.where(id: reopened_conversations.pluck(:conversation_id)) if @config[:filters][:labels].present?

    # Get all assignments during the time range
    latest_assignments = ConversationAssignment
                         .select('DISTINCT ON (conversation_id) *')
                         .where('created_at >= ?', @time_range.begin)
                         .where(account_id: @account.id, conversation_id: base_query.pluck(:id))
                         .order('conversation_id, created_at ASC')

    latest_assignments_with_required_columns = ConversationAssignment.select('conversation_id, inbox_id, assignee_id, team_id, created_at').where(id: latest_assignments.pluck(:id))
    # Handle conversations without assignments by creating a union query
    conversations_without_assignments = base_query
                                        .where.not(id: latest_assignments_with_required_columns.pluck(:conversation_id))
                                        .select('id AS conversation_id, inbox_id, assignee_id, NULL AS team_id, created_at')

    # Combine both queries using a UNION
    combined_query = ConversationAssignment.connection.unprepared_statement do
      "((#{latest_assignments_with_required_columns.to_sql}) UNION (#{conversations_without_assignments.to_sql})) AS conversation_assignments"
    end

    base_query = ConversationAssignment.from(combined_query)

    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info 'Reopened'
    group_and_count_conversation_assignment(base_query, @config[:group_by])
  end

  def handled
    # carry forwarded + new assigned + reopened
    if @config[:group_by].present?
      # For grouped data, we need to merge the results
      result = {}
      [carry_forwarded, new_assigned, reopened].each do |data|
        data.each do |key, value|
          result[key] ||= 0
          result[key] += value
        end
      end
      result
    else
      # For non-grouped data, we can simply sum the values
      carry_forwarded + new_assigned + reopened
    end
  end

  def bot_handled
    # set filter as @@config[:filters][:agents] = [bot_user.id]
    @config[:filters][:agents] = [bot_user.id]

    new_assigned
  end

  def pre_sale_queries
    base_query = @account.conversations.with_intent('PRE_SALES').where(created_at: @time_range)

    base_query = label_filtered_conversations.where(id: base_query.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?

    group_and_count(base_query, @config[:group_by])
  end

  def bot_user
    query = @account.users.where('email LIKE ?', 'cx.%@bitespeed.co')
    Rails.logger.info "bot_user query: #{query.to_sql}"
    query.first
  end

  def open
    # conversations that remain in an “Open” state at the end of the specified period.
    open_conversations = ConversationStatus.from("(#{latest_conversation_statuses.to_sql}) AS conversation_statuses").where(status: :open)

    base_query = @account.conversations.where(id: open_conversations.pluck(:conversation_id))

    base_query = label_filtered_conversations.where(id: open_conversations.pluck(:conversation_id)) if @config[:filters][:labels].present?

    latest_assignments = ConversationAssignment
                         .select('DISTINCT ON (conversation_id) *')
                         .where('created_at < ?', @time_range.end)
                         .where(account_id: @account.id, conversation_id: base_query.pluck(:id))
                         .order('conversation_id, created_at DESC')

    base_query = ConversationAssignment.from("(#{latest_assignments.to_sql}) AS conversation_assignments")

    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "open_conversations: #{base_query.to_sql}"

    group_and_count_conversation_assignment(base_query, @config[:group_by])
  end

  def resolved
    # conversations that get resolved at the end of the specified period. we use this so we remove the conversations that get reopened in the time range from reporting events
    resolved_conversations = ConversationStatus.from("(#{latest_conversation_statuses.to_sql}) AS conversation_statuses")
                                               .where(status: :resolved)

    # Get conversations that were resolved in the time range
    base_query = @account.reporting_events.select('DISTINCT ON (conversation_id) *')
                         .where(name: 'conversation_resolved', created_at: @time_range)
                         .where(conversation_id: resolved_conversations.pluck(:conversation_id))
                         .order('created_at DESC')

    # Apply filters
    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "resolved conversations query: #{base_query.to_sql}"

    base_query = ReportingEvent.where(id: base_query.pluck(:id))

    group_and_count_reporting_events(base_query, @config[:group_by])
  end

  def resolved_in_time_range
    # conversations that get resolved at the end of the specified period. we use this so we remove the conversations that get reopened in the time range from reporting events
    resolved_conversations = ConversationStatus.from("(#{latest_conversation_statuses.to_sql}) AS conversation_statuses")
                                               .where(status: :resolved)
                                               .joins(:conversation)
                                               .where('conversations.created_at BETWEEN ? AND ?', @time_range.begin, @time_range.end)

    # Get conversations that were resolved in the time range
    base_query = @account.reporting_events.select('DISTINCT ON (conversation_id) *')
                         .where(name: 'conversation_resolved', created_at: @time_range)
                         .where(conversation_id: resolved_conversations.pluck(:conversation_id))
                         .order('created_at DESC')

    # Apply filters
    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "resolved conversations query: #{base_query.to_sql}"

    base_query = ReportingEvent.where(id: base_query.pluck(:id))

    group_and_count_reporting_events(base_query, @config[:group_by])
  end

  def resolved_in_pre_time_range
    # conversations that get resolved at the end of the specified period. we use this so we remove the conversations that get reopened in the time range from reporting events
    resolved_conversations = ConversationStatus.from("(#{latest_conversation_statuses.to_sql}) AS conversation_statuses")
                                               .where(status: :resolved)
                                               .joins(:conversation)
                                               .where('conversations.created_at < ?', @time_range.begin)

    # Get conversations that were resolved in the time range
    base_query = @account.reporting_events.select('DISTINCT ON (conversation_id) *')
                         .where(name: 'conversation_resolved', created_at: @time_range)
                         .where(conversation_id: resolved_conversations.pluck(:conversation_id))
                         .order('created_at DESC')

    # Apply filters
    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "resolved conversations query: #{base_query.to_sql}"

    base_query = ReportingEvent.where(id: base_query.pluck(:id))

    group_and_count_reporting_events(base_query, @config[:group_by])
  end

  def bot_resolved
    newly_created_conversations = @account.conversations.where(created_at: @time_range)

    # Get conversations that were resolved in the time range
    base_query = @account.reporting_events.select('DISTINCT ON (conversation_id) *')
                         .where(name: 'conversation_resolved', created_at: @time_range)
                         .where(conversation_id: newly_created_conversations.pluck(:id))
                         .order('created_at DESC')

    # Apply filters
    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: bot_user.id)

    Rails.logger.info "resolved conversations query: #{base_query.to_sql}"

    base_query = ReportingEvent.where(id: base_query.pluck(:id))

    group_and_count_reporting_events(base_query, @config[:group_by])
  end

  def snoozed
    # conversations that remain in an “Snoozed” state at the end of the specified period.
    snoozed_conversations = ConversationStatus.from("(#{latest_conversation_statuses.to_sql}) AS conversation_statuses").where(status: :snoozed)

    base_query = @account.conversations.where(id: snoozed_conversations.pluck(:conversation_id))

    base_query = label_filtered_conversations.where(id: snoozed_conversations.pluck(:conversation_id)) if @config[:filters][:labels].present?

    Rails.logger.info "snoozed_conversations: #{base_query.to_sql}"

    latest_assignments = ConversationAssignment
                         .select('DISTINCT ON (conversation_id) *')
                         .where('created_at < ?', @time_range.end)
                         .where(account_id: @account.id, conversation_id: base_query.pluck(:id))
                         .order('conversation_id, created_at DESC')

    base_query = ConversationAssignment.from("(#{latest_assignments.to_sql}) AS conversation_assignments")

    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    group_and_count_conversation_assignment(base_query, @config[:group_by])
  end

  def waiting_agent_response
    # conversations that are open and waiting an agent response at the end of the specified period.

    open_conversations = ConversationStatus.from("(#{latest_conversation_statuses.to_sql}) AS conversation_statuses").where(status: :open)

    conversation_waiting_agent_response = latest_messages_by_type(
      open_conversations.pluck(:conversation_id),
      :incoming
    )

    Rails.logger.info "conversation_waiting_agent_response: #{conversation_waiting_agent_response.to_sql}"

    base_query = @account.conversations.where(id: conversation_waiting_agent_response.pluck(:conversation_id))

    if @config[:filters][:labels].present?
      base_query = label_filtered_conversations.where(id: conversation_waiting_agent_response.pluck(:conversation_id))
    end
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "waiting_agent_response: #{base_query.to_sql}"

    group_and_count(base_query, @config[:group_by])
  end

  def waiting_customer_response
    # conversations that are open and waiting a customer response at the end of the specified period.
    open_conversations = ConversationStatus.from("(#{latest_conversation_statuses.to_sql}) AS conversation_statuses").where(status: :open)

    conversation_waiting_customer_response = latest_messages_by_type(
      open_conversations.pluck(:conversation_id),
      [:outgoing, :template]
    )

    base_query = @account.conversations.where(id: conversation_waiting_customer_response.pluck(:conversation_id))

    if @config[:filters][:labels].present?
      base_query = label_filtered_conversations.where(id: conversation_waiting_customer_response.pluck(:conversation_id))
    end
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "waiting_customer_response: #{base_query.to_sql}"

    group_and_count(base_query, @config[:group_by])
  end

  def total_calling_nudged_conversations
    base_query = @account.conversations
                         .where("additional_attributes->>'source_context' IS NOT NULL")
                         .where("(additional_attributes->>'nudge_created')::timestamp BETWEEN ? AND ?
                         OR (additional_attributes->>'nudge_created' IS NULL AND created_at BETWEEN ? AND ?)",
                                @time_range.begin, @time_range.end,
                                @time_range.begin, @time_range.end)

    base_query = label_filtered_conversations.where(id: base_query.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "total_calling_nudged_conversations: #{base_query.to_sql}"

    group_and_count(base_query, @config[:group_by])
  end

  def scheduled_call_conversations
    base_query = @account.conversations
                         .where("additional_attributes->>'source_context' IS NOT NULL")
                         .where("custom_attributes->>'calling_status' = 'Scheduled'")
                         .where("(additional_attributes->>'nudge_created')::timestamp BETWEEN ? AND ?
                         OR (additional_attributes->>'nudge_created' IS NULL AND created_at BETWEEN ? AND ?)",
                                @time_range.begin, @time_range.end,
                                @time_range.begin, @time_range.end)

    base_query = label_filtered_conversations.where(id: base_query.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "scheduled_call_conversations: #{base_query.to_sql}"

    group_and_count(base_query, @config[:group_by])
  end

  def not_picked_up_call_conversations
    base_query = @account.conversations
                         .where("additional_attributes->>'source_context' IS NOT NULL")
                         .where("custom_attributes->>'calling_status' = 'Not Picked'")
                         .where("(additional_attributes->>'nudge_created')::timestamp BETWEEN ? AND ?
                         OR (additional_attributes->>'nudge_created' IS NULL AND created_at BETWEEN ? AND ?)",
                                @time_range.begin, @time_range.end,
                                @time_range.begin, @time_range.end)

    base_query = label_filtered_conversations.where(id: base_query.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "not_picked_up_call_conversations: #{base_query.to_sql}"

    group_and_count(base_query, @config[:group_by])
  end

  def follow_up_call_conversations
    base_query = @account.conversations
                         .where("additional_attributes->>'source_context' IS NOT NULL")
                         .where("custom_attributes->>'calling_status' = 'Follow-up'")
                         .where("(additional_attributes->>'nudge_created')::timestamp BETWEEN ? AND ?
                         OR (additional_attributes->>'nudge_created' IS NULL AND created_at BETWEEN ? AND ?)",
                                @time_range.begin, @time_range.end,
                                @time_range.begin, @time_range.end)

    base_query = label_filtered_conversations.where(id: base_query.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "follow_up_call_conversations: #{base_query.to_sql}"

    group_and_count(base_query, @config[:group_by])
  end

  def converted_call_conversations
    base_query = @account.conversations
                         .where("additional_attributes->>'source_context' IS NOT NULL")
                         .where("custom_attributes->>'calling_status' = 'Converted'")
                         .where("(additional_attributes->>'nudge_created')::timestamp BETWEEN ? AND ?
                         OR (additional_attributes->>'nudge_created' IS NULL AND created_at BETWEEN ? AND ?)",
                                @time_range.begin, @time_range.end,
                                @time_range.begin, @time_range.end)

    base_query = label_filtered_conversations.where(id: base_query.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "converted_call_conversations: #{base_query.to_sql}"

    group_and_count(base_query, @config[:group_by])
  end

  def dropped_call_conversations
    base_query = @account.conversations
                         .where("additional_attributes->>'source_context' IS NOT NULL")
                         .where("custom_attributes->>'calling_status' = 'Dropped'")
                         .where("(additional_attributes->>'nudge_created')::timestamp BETWEEN ? AND ?
                         OR (additional_attributes->>'nudge_created' IS NULL AND created_at BETWEEN ? AND ?)",
                                @time_range.begin, @time_range.end,
                                @time_range.begin, @time_range.end)

    base_query = label_filtered_conversations.where(id: base_query.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(assignee_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "dropped_call_conversations: #{base_query.to_sql}"

    group_and_count(base_query, @config[:group_by])
  end

  def avg_time_to_call_after_nudge
    base_query = @account.reporting_events.where(name: 'conversation_first_call', created_at: @time_range).joins(:conversation).where("conversations.additional_attributes->>'source_context' IS NOT NULL")

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_resolution_time): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def avg_time_to_convert
    base_query = @account.reporting_events.where(name: 'conversation_call_converted', created_at: @time_range).joins(:conversation).where("conversations.additional_attributes->>'source_context' IS NOT NULL").where("custom_attributes->>'calling_status' = 'Converted'")

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_resolution_time): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def avg_time_to_drop
    base_query = @account.reporting_events.where(name: 'conversation_call_dropped', created_at: @time_range).joins(:conversation).where("conversations.additional_attributes->>'source_context' IS NOT NULL").where("custom_attributes->>'calling_status' = 'Dropped'")

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_time_to_drop): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def avg_follow_up_calls
    base_query = @account.reporting_events.where(name: 'conversation_follow_up_call', created_at: @time_range).joins(:conversation).where("conversations.additional_attributes->>'source_context' IS NOT NULL")

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_resolution_time): #{base_query.to_sql}"

    base_query = base_query.group(:conversation_id, :user_id).select('conversation_id, user_id, COUNT(*) as value, COUNT(*) as value_in_business_hours')

    base_query = ReportingEvent.from("(#{base_query.to_sql}) AS reporting_events")

    Rails.logger.info "Base query(avg_follow_up_calls): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  ### Agent Metrics ###
  def avg_first_response_time
    # the average time elapsed between a ticket getting assigned to an agent and the agent responding to it for the first time.
    base_query = @account.reporting_events.where(name: 'first_response', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_first_response_time): #{base_query.to_sql}"

    Rails.logger.info "get_grouped_average(base_query) #{get_grouped_average(base_query)}"

    get_grouped_average(base_query)
  end

  def avg_resolution_time
    # the average time elapsed between a ticket getting assigned to an agent and the agent sending the last message to the customer (only resolved tickets are included in this calculation)
    base_query = @account.reporting_events.where(name: 'conversation_resolved', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_resolution_time): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def bot_avg_resolution_time
    base_query = @account.reporting_events.joins(:conversation).where(name: 'conversation_resolved', created_at: @time_range, conversations: {
                                                                        created_at: @time_range
                                                                      })

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?

    base_query = base_query.where(user_id: bot_user.id)

    Rails.logger.info "Base query(avg_resolution_time): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def avg_resolution_time_of_time_range
    base_query = @account.reporting_events.where(name: 'conversation_resolved', created_at: @time_range).joins(:conversation).where('conversations.created_at > ?', @time_range.begin)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    get_grouped_average(base_query)
  end

  def avg_resolution_time_of_pre_time_range
    base_query = @account.reporting_events.where(name: 'conversation_resolved', created_at: @time_range).joins(:conversation).where('conversations.created_at < ?', @time_range.begin)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    get_grouped_average(base_query)
  end

  def bot_assign_to_agent
    # find all the conversations where assignment changed from bot to someone else other than bot.
    conversations_assigned_by_bot = ConversationAssignment
                                    .select('DISTINCT a2.conversation_id')
                                    .from('conversation_assignments a1')
                                    .joins('JOIN conversation_assignments a2 ON a1.conversation_id = a2.conversation_id AND a1.created_at < a2.created_at')
                                    .where(a1: { assignee_id: bot_user.id })
                                    .where.not(a2: { assignee_id: bot_user.id })
                                    .where(a2: { created_at: @time_range })

    Rails.logger.info "conversations_assigned_by_bot: #{conversations_assigned_by_bot.to_sql}"

    base_query = @account.conversations.where(id: conversations_assigned_by_bot, created_at: @time_range)

    base_query = label_filtered_conversations.where(id: conversations_assigned_by_bot) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?

    group_and_count(base_query, @config[:group_by])
  end

  def avg_resolution_time_of_new_assigned_conversations
    # the average time elapsed between a ticket getting assigned to an agent and the agent sending the last message to the customer (only resolved tickets are included in this calculation)
    # but split by conversations that moved to resolved from new_assigned
    # means need to check the conversations where created in the same time range as the time range for which the report is generated
    base_query = @account.reporting_events.joins(:conversation).where(name: 'conversation_resolved', conversations: { created_at: @time_range }, created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_resolution_time_of_new_assigned_conversations): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def avg_resolution_time_of_carry_forwarded_conversations
    # the average time elapsed between a ticket getting assigned to an agent and the agent sending the last message to the customer (only resolved tickets are included in this calculation)
    # but split by conversations that moved to resolved from carry_forwarded
    # means need to check the conversations where created before the start of the time range and are still not resolved at the start of the time range for which the report is generated

    # not_resolved_conversations_before_time_range = ConversationStatus.from("(#{latest_conversation_statuses_before_time_range.to_sql}) AS conversation_statuses").where.not(status: :resolved)

    # conversations_without_conversation_status_before_time_range = @account.conversations.where.not(id: ConversationStatus.from(
    #   "(#{latest_conversation_statuses_before_time_range.to_sql}) AS conversation_statuses"
    # ).pluck(:conversation_id)).where('created_at < ?', @time_range.begin).where('(updated_at >= ?) OR (updated_at <= ? AND status != ?)', @time_range.begin, @time_range.begin, Conversation.statuses[:resolved])

    # TODO: refine this too

    carry_forwarded_conversations = @account.conversations.where('created_at < ?', @time_range.begin).where.not(status: Conversation.statuses[:resolved])

    base_query = @account.reporting_events.where(name: 'conversation_resolved', conversation_id: [
      carry_forwarded_conversations.pluck(:id)
    ].flatten, created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_resolution_time_of_carry_forwarded_conversations): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def avg_resolution_time_of_reopened_conversations
    # the average time elapsed between a ticket getting assigned to an agent and the agent sending the last message to the customer (only resolved tickets are included in this calculation)
    # but split by conversations that moved to resolved from reopened
    # means need to check the conversations where created before the start of the time range and is resolved at the start of the time range for which the report is generated

    resolved_conversations_before_time_range = ConversationStatus.from("(#{latest_conversation_statuses_before_time_range.to_sql}) AS conversation_statuses").where(status: :resolved)

    reopened_conversations = first_conversation_statuses.where(conversation_id: resolved_conversations_before_time_range.pluck(:conversation_id)).where(status: :open)

    base_query = @account.reporting_events.where(name: 'conversation_resolved', conversation_id: reopened_conversations.pluck(:conversation_id), created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:conversation_id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_resolution_time_of_reopened_conversations): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def avg_response_time
    # the average time elapsed b/w a cx messaging and agent replying during the whole conversation
    base_query = @account.reporting_events.where(name: 'reply_time', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_response_time): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def avg_csat_score
    # Score given by cx at the end of each conversation resolution
    base_query = @account.csat_survey_responses.where(created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.filter_by_inbox_id(@config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.filter_by_assigned_agent_id(@config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_csat_score): #{base_query.to_sql}"

    get_grouped_average_csat(base_query)
  end

  def median_first_response_time
    # the median time elapsed between a ticket getting assigned to an agent and the agent responding to it for the first time.
    base_query = @account.reporting_events.where(name: 'first_response', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(median_first_response_time): #{base_query.to_sql}"

    get_grouped_median(base_query)
  end

  def median_resolution_time
    # the median time elapsed between a ticket getting assigned to an agent and the agent sending the last message to the customer (only resolved tickets are included in this calculation)
    base_query = @account.reporting_events.where(name: 'conversation_resolved', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(median_resolution_time): #{base_query.to_sql}"

    get_grouped_median(base_query)
  end

  def median_resolution_time_of_new_assigned_conversations
    # the median time elapsed between a ticket getting assigned to an agent and the agent sending the last message to the customer (only resolved tickets are included in this calculation)
    # but split by conversations that moved to resolved from new_assigned
    # means need to check the conversations where created in the same time range as the time range for which the report is generated
    base_query = @account.reporting_events.joins(:conversation).where(name: 'conversation_resolved', conversations: { created_at: @time_range }, created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(median_resolution_time_of_new_assigned_conversations): #{base_query.to_sql}"
    get_grouped_median(base_query)
  end

  def median_resolution_time_of_carry_forwarded_conversations
    # the median time elapsed between a ticket getting assigned to an agent and the agent sending the last message to the customer (only resolved tickets are included in this calculation)
    # but split by conversations that moved to resolved from carry_forwarded
    # means need to check the conversations where created before the start of the time range and are still not resolved at the start of the time range for which the report is generated

    # not_resolved_conversations_before_time_range = ConversationStatus.from("(#{latest_conversation_statuses_before_time_range.to_sql}) AS conversation_statuses").where.not(status: :resolved)

    # conversations_without_conversation_status_before_time_range = @account.conversations.where.not(id: ConversationStatus.from(
    #   "(#{latest_conversation_statuses_before_time_range.to_sql}) AS conversation_statuses"
    # ).pluck(:conversation_id)).where('created_at < ?', @time_range.begin).where('(updated_at >= ?) OR (updated_at <= ? AND status != ?)', @time_range.begin, @time_range.begin, Conversation.statuses[:resolved])

    carry_forwarded_conversations = @account.conversations.where('created_at < ?', @time_range.begin).where.not(status: Conversation.statuses[:resolved])

    base_query = @account.reporting_events.where(name: 'conversation_resolved', conversation_id: [
      carry_forwarded_conversations.pluck(:id)
    ].flatten, created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(median_resolution_time_of_carry_forwarded_conversations): #{base_query.to_sql}"

    get_grouped_median(base_query)
  end

  def median_resolution_time_of_reopened_conversations
    # the median time elapsed between a ticket getting assigned to an agent and the agent sending the last message to the customer (only resolved tickets are included in this calculation)
    # but split by conversations that moved to resolved from reopened
    # means need to check the conversations where created before the start of the time range and is resolved at the start of the time range for which the report is generated

    resolved_conversations_before_time_range = ConversationStatus.from("(#{latest_conversation_statuses_before_time_range.to_sql}) AS conversation_statuses").where(status: :resolved)

    reopened_conversations = first_conversation_statuses.where(conversation_id: resolved_conversations_before_time_range.pluck(:conversation_id)).where(status: :open)

    base_query = @account.reporting_events.where(name: 'conversation_resolved', conversation_id: reopened_conversations.pluck(:conversation_id), created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:conversation_id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(median_resolution_time_of_reopened_conversations): #{base_query.to_sql}"

    get_grouped_median(base_query)
  end

  def median_response_time
    # the median time elapsed b/w a cx messaging and agent replying during the whole conversation
    base_query = @account.reporting_events.where(name: 'reply_time', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(median_response_time): #{base_query.to_sql}"

    get_grouped_median(base_query)
  end

  def median_csat_score
    # median score given by cx at the end of each conversation resolution
    base_query = @account.csat_survey_responses.where(created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.filter_by_inbox_id(@config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.filter_by_assigned_agent_id(@config[:filters][:agents]) if @config[:filters][:agents].present?
    base_query = base_query.filter_by_team_id(@config[:filters][:teams]) if @config[:filters][:teams].present?

    Rails.logger.info "Base query(median_csat_score): #{base_query.to_sql}"

    get_grouped_median_csat(base_query)
  end

  def total_inbound_calls_handled
    base_query = @account.reporting_events.where(name: 'conversation_inbound_call', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(total_inbound_calls): #{base_query.to_sql}"

    group_and_count_reporting_events_without_distinct(base_query, @config[:group_by])
  end

  def total_calls_missed
    base_query = @account.reporting_events.where(
      name: %w[conversation_missed_call_ooo conversation_missed_call_busy],
      created_at: @time_range
    )

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(total_missed_calls): #{base_query.to_sql}"

    group_and_count_reporting_events_without_distinct(base_query, @config[:group_by])
  end

  def total_inbound_call_conversations
    base_query = @account.reporting_events.where(name: 'conversation_inbound_call', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(total_inbound_call_conversations): #{base_query.to_sql}"

    group_and_count_reporting_events(base_query, @config[:group_by])
  end

  def inbound_calls_resolved
    inbound_calls = @account.reporting_events.where(name: 'conversation_inbound_call', created_at: @time_range)

    base_query = @account.reporting_events.select('DISTINCT ON (conversation_id) *')
                         .where(name: 'conversation_resolved', created_at: @time_range)
                         .where(conversation_id: inbound_calls.pluck(:conversation_id))
                         .order('created_at DESC')

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(total_inbound_calls_resolved): #{base_query.to_sql}"

    base_query = ReportingEvent.where(id: base_query.pluck(:id))

    group_and_count_reporting_events(base_query, @config[:group_by])
  end

  def avg_call_wait_time
    @config[:filters][:labels] = Array(@config[:filters][:labels]) + ['inbound-call']

    base_query = @account.reporting_events.where(name: 'conversation_call_waiting_time', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_call_wait_time): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  def avg_call_handling_time
    @config[:filters][:labels] = Array(@config[:filters][:labels]) + ['inbound-call']

    base_query = @account.reporting_events.where(name: 'conversation_call_handling_time', created_at: @time_range)

    base_query = base_query.where(conversation_id: label_filtered_conversations.pluck(:id)) if @config[:filters][:labels].present?
    base_query = base_query.where(inbox_id: @config[:filters][:inboxes]) if @config[:filters][:inboxes].present?
    base_query = base_query.where(user_id: @config[:filters][:agents]) if @config[:filters][:agents].present?

    Rails.logger.info "Base query(avg_call_handling_time): #{base_query.to_sql}"

    get_grouped_average(base_query)
  end

  ### Helper Methods ###

  def get_grouped_average(events)
    if @config[:group_by].present?
      Rails.logger.info "events: #{events.to_sql}"
      if @config[:group_by] == 'working_hours'
        result = events.joins(:conversation)
                       .group("COALESCE((conversations.additional_attributes->>'working_hours')::boolean, true)")
                       .average(average_value_key)
                       .transform_keys { |key| key ? 'working_hours' : 'non_working_hours' }
        {
          'working_hours' => result['working_hours'] || nil,
          'non_working_hours' => result['non_working_hours'] || nil,
          'total' => events.group(group_by_key).average(average_value_key) || nil
        }
      else
        events.group(group_by_key).average(average_value_key)
      end
    else
      events.average(average_value_key)
    end
  end

  def get_grouped_median(events)
    if @config[:group_by].present?
      group_key = group_by_key
      value_key = average_value_key

      Rails.logger.info "get_grouped_median Group key: #{group_key.inspect}, Value key: #{value_key.inspect}"

      return {} if group_key.nil? || value_key.nil?

      Rails.logger.info "events: #{events.to_sql}"

      begin
        result = events.group(group_key)
                       .pluck(Arel.sql(sanitize_sql_for_conditions(["#{group_key}, ARRAY_AGG(#{value_key})"])))
                       .to_h
                       .transform_values { |values| calculate_median(values) }
        Rails.logger.info "Grouped median result: #{result.inspect}"
        result
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Error in get_grouped_median: #{e.message}"
        {}
      end
    else
      calculate_median(events.pluck(average_value_key))
    end
  end

  def calculate_median(array)
    return nil if array.empty?

    sorted = array.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def sanitize_sql_for_conditions(sql)
    ActiveRecord::Base.send(:sanitize_sql_for_conditions, sql)
  end

  def get_grouped_average_csat(events)
    if @config[:group_by].present?
      case @config[:group_by]
      when 'agent'
        events.group(:assigned_agent_id).average(:rating)
      when 'inbox'
        events.joins(:conversation).group('conversations.inbox_id').average(:rating)
      end
    else
      events.average(:rating)
    end
  end

  def get_grouped_median_csat(events)
    if @config[:group_by].present?
      group_key, join_condition = case @config[:group_by]
                                  when 'agent'
                                    [:assigned_agent_id, nil]
                                  when 'inbox'
                                    ['conversations.inbox_id', :conversation]
                                  else
                                    [nil, nil]
                                  end

      Rails.logger.info "CSAT Group key: #{group_key.inspect}, Join condition: #{join_condition.inspect}"

      return {} if group_key.nil?

      begin
        query = join_condition ? events.joins(join_condition) : events
        result = query.group(group_key)
                      .pluck(Arel.sql(sanitize_sql_for_conditions(["#{group_key}, ARRAY_AGG(rating)"])))
                      .to_h
                      .transform_values { |ratings| calculate_median(ratings) }
        Rails.logger.info "Grouped median CSAT result: #{result.inspect}"
        result
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error "Error in get_grouped_median_csat: #{e.message}"
        {}
      end
    else
      calculate_median(events.pluck(:rating))
    end
  end

  def average_value_key
    @config[:filters][:business_hours].present? && @config[:filters][:business_hours] == true ? :value_in_business_hours : :value
  end

  def group_by_key
    case @config[:group_by]
    when 'agent'
      :user_id
    when 'inbox'
      :inbox_id
    end
  end

  def group_and_count(query, group_by_param)
    Rails.logger.info "group_and_count query: #{query.to_sql}"

    case group_by_param
    when 'agent'
      query.group(:assignee_id).count
    when 'inbox'
      query.group(:inbox_id).count
    when 'working_hours'
      # Group by working_hours using additional_attributes
      result = query.group("COALESCE((additional_attributes->>'working_hours')::boolean, true)")
                    .count
                    .transform_keys do |key|
        # Transform true/false keys to working_hours/non_working_hours
        key ? 'working_hours' : 'non_working_hours'
      end

      # Ensure both keys exist with at least 0 as value
      {
        'working_hours' => result['working_hours'] || 0,
        'non_working_hours' => result['non_working_hours'] || 0
      }
    else
      query.count
    end
  rescue StandardError => e
    Rails.logger.error "Error in group_and_count: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def group_and_count_conversation_assignment(query, group_by_param)
    Rails.logger.info "group_and_count query: #{query.to_sql}"

    case group_by_param
    when 'agent'
      query.group(:assignee_id).distinct.count(:conversation_id)
    when 'inbox'
      query.group(:inbox_id).distinct.count(:conversation_id)
    when 'working_hours'
      # Join with conversations table to access additional_attributes
      result = query.joins(:conversation)
                    .group("COALESCE((conversations.additional_attributes->>'working_hours')::boolean, true)")
                    .distinct
                    .count(:conversation_id)
                    .transform_keys { |key| key ? 'working_hours' : 'non_working_hours' }

      # Ensure both keys exist with at least 0 as value
      {
        'working_hours' => result['working_hours'] || 0,
        'non_working_hours' => result['non_working_hours'] || 0
      }
    else
      query.distinct.count(:conversation_id)
    end
  rescue StandardError => e
    Rails.logger.error "Error in group_and_count_conversation_assignment: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def group_and_count_reporting_events(query, group_by_param)
    case group_by_param
    when 'working_hours'
      conversation_ids = query.distinct.pluck(:conversation_id)
      result = Conversation.where(id: conversation_ids)
                           .group("COALESCE((additional_attributes->>'working_hours')::boolean, true)")
                           .count
                           .transform_keys { |key| key ? 'working_hours' : 'non_working_hours' }

      {
        'working_hours' => result['working_hours'] || 0,
        'non_working_hours' => result['non_working_hours'] || 0
      }
    when 'agent'
      query.group(:user_id).distinct.count(:conversation_id)
    when 'inbox'
      query.group(:inbox_id).distinct.count(:conversation_id)
    else
      query.distinct.count(:conversation_id)
    end
  rescue StandardError => e
    Rails.logger.error "Error in group_and_count_reporting_events: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def group_and_count_reporting_events_without_distinct(query, group_by_param)
    case group_by_param
    when 'working_hours'
      conversation_ids = query.distinct.pluck(:conversation_id)
      result = Conversation.where(id: conversation_ids)
                           .group("COALESCE((additional_attributes->>'working_hours')::boolean, true)")
                           .count
                           .transform_keys { |key| key ? 'working_hours' : 'non_working_hours' }

      {
        'working_hours' => result['working_hours'] || 0,
        'non_working_hours' => result['non_working_hours'] || 0
      }
    when 'agent'
      query.group(:user_id).count
    when 'inbox'
      query.group(:inbox_id).count
    else
      query.count
    end
  rescue StandardError => e
    Rails.logger.error "Error in group_and_count_reporting_events: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def first_conversation_statuses
    ConversationStatus.select('DISTINCT ON (conversation_id) *').where(
      account_id: account.id,
      created_at: @time_range
    ).order('conversation_id, created_at ASC')
  end

  def latest_conversation_statuses
    ConversationStatus.select('DISTINCT ON (conversation_id) *').where(
      account_id: account.id,
      created_at: @time_range
    ).order('conversation_id, created_at DESC')
  end

  def latest_conversation_statuses_before_time_range
    ConversationStatus.select('DISTINCT ON (conversation_id) *').where(
      account_id: account.id
    ).where('created_at < ?', @time_range.begin).order('conversation_id, created_at DESC')
  end

  def latest_messages_by_type(conversation_ids, message_types)
    Message
      .select('DISTINCT ON (messages.conversation_id) messages.*')
      .where(conversation_id: conversation_ids, created_at: @time_range)
      .where.not(message_type: :activity)
      .where(message_type: message_types)
      .order('messages.conversation_id, messages.created_at DESC')
  end

  def label_filtered_conversations
    convs = @account.conversations.tagged_with(@config[:filters][:labels], :any => true).where(created_at: @time_range)
    Rails.logger.info "label_filtered_conversations: #{convs.to_sql}"
    convs
  end

  def bot_label_filtered_conversations
    convs = @account.conversations.tagged_with(@config[:filters][:labels], :any => true).where(created_at: @time_range, assignee_id: bot_user.id)
    Rails.logger.info "bot_label_filtered_conversations: #{convs.to_sql}"
    convs
  end
end
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Layout/LineLength
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Rails/HelperInstanceVariable
# rubocop:enable Metrics/PerceivedComplexity
