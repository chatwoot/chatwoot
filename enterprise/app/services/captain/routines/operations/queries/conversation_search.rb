class Captain::Routines::Operations::Queries::ConversationSearch < Captain::Routines::Operations::Query
  returns :collection

  configure(
    name: 'conversations.search', effect: 'read',
    description: 'Find conversations using deterministic filters.',
    arguments: {
      status: 'open, resolved, pending, or snoozed', inbox: 'inbox name or ID',
      contact: 'contact name, email, phone number, ID, or reference',
      assignee: 'agent name, email, ID, or unassigned', team: 'team name, ID, or unassigned',
      waiting_for: 'agent_reply or customer_reply', waiting_longer_than: 'duration such as 12h',
      snooze_due: 'relative date such as today, evaluated against snoozed_until in the account timezone',
      priority: 'low, medium, high, or urgent', labels: 'array of label names',
      created: 'relative date or range', last_activity: 'relative date or range'
    }
  )

  def execute(**filters)
    # TODO: Page large selections and checkpoint each page when Routine executions become durable.
    scope = account.conversations.includes(:assignee, :contact, :inbox, :team, :labels)
    scope = apply_identity_filters(scope, filters)
    scope = apply_assignment_filters(scope, filters)
    scope = apply_taxonomy_filters(scope, filters)
    scope = apply_time_filters(scope, filters)
    scope = apply_waiting_filter(scope, filters[:waiting_for], filters[:waiting_longer_than])

    scope.reorder(last_activity_at: :asc, id: :asc).map { |conversation| conversation_data(conversation) }
  end

  private

  def apply_identity_filters(scope, filters)
    scope = scope.where(status: Conversation.statuses.fetch(filters[:status])) if filters[:status].present?
    scope = scope.where(inbox: inbox!(filters[:inbox])) if filters[:inbox].present?
    filters[:contact].present? ? scope.where(contact: resolve_contact(filters[:contact])) : scope
  end

  def apply_assignment_filters(scope, filters)
    scope = apply_assignment(scope, :assignee, filters[:assignee]) if filters[:assignee].present?
    filters[:team].present? ? apply_assignment(scope, :team, filters[:team]) : scope
  end

  def apply_taxonomy_filters(scope, filters)
    scope = scope.where(priority: Conversation.priorities.fetch(filters[:priority])) if filters[:priority].present?
    filters[:labels].present? ? scope.tagged_with(Array(filters[:labels])) : scope
  end

  def apply_time_filters(scope, filters)
    scope = scope.where(created_at: time_range!(filters[:created])) if filters[:created].present?
    scope = scope.where(last_activity_at: time_range!(filters[:last_activity])) if filters[:last_activity].present?
    filters[:snooze_due].present? ? scope.where(snoozed_until: time_range!(filters[:snooze_due])) : scope
  end

  def resolve_contact(value)
    return contact!(value) if record_id(value).to_s.match?(/\A\d+\z/)

    query = record_id(value).to_s
    account.contacts.where(
      'LOWER(name) = :query OR LOWER(email) = :query OR phone_number = :raw OR identifier = :raw',
      query: query.downcase,
      raw: query
    ).sole
  end

  def apply_assignment(scope, type, value)
    return scope.where(type => nil) if value.to_s == 'unassigned'

    scope.where(type => type == :assignee ? agent!(value) : team!(value))
  end

  def apply_waiting_filter(scope, waiting_for, waiting_longer_than)
    return apply_waiting_duration(scope, waiting_longer_than) if waiting_for.blank?

    case waiting_for
    when 'agent_reply'
      scope = scope.where.not(waiting_since: nil)
      waiting_longer_than.present? ? scope.where(waiting_since: ..(started_at - duration!(waiting_longer_than))) : scope
    when 'customer_reply'
      latest_message_filter(scope, waiting_longer_than)
    else
      raise ArgumentError, "Invalid waiting_for '#{waiting_for}'"
    end
  end

  def apply_waiting_duration(scope, value)
    return scope if value.blank?

    scope.where(waiting_since: ..(started_at - duration!(value)))
  end

  def latest_message_filter(scope, waiting_longer_than)
    latest_messages = account.messages
                             .where(private: false, message_type: %i[incoming outgoing])
                             .select('DISTINCT ON (conversation_id) conversation_id, message_type, created_at')
                             .reorder('conversation_id, created_at DESC, id DESC')
    latest_outgoing = Message.unscoped.from("(#{latest_messages.to_sql}) routine_latest_messages")
                             .where(routine_latest_messages: { message_type: Message.message_types.fetch('outgoing') })
    if waiting_longer_than.present?
      latest_outgoing = latest_outgoing.where('routine_latest_messages.created_at <= ?', started_at - duration!(waiting_longer_than))
    end
    scope.where(id: latest_outgoing.select('routine_latest_messages.conversation_id'))
  end
end
