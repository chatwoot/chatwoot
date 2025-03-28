module ConversationFilterService
  def filter_by_assignee_type(conversations, assignee_type, current_user)
    case assignee_type
    when 'me'
      conversations.assigned_to(current_user)
    when 'unassigned'
      conversations.unassigned
    when 'assigned'
      conversations.assigned
    else
      conversations
    end
  end

  def filter_by_conversation_type(conversations, conversation_type, current_user, current_account)
    case conversation_type
    when 'mention'
      conversation_ids = current_account.mentions.where(user: current_user).pluck(:conversation_id)
      conversations.where(id: conversation_ids)
    when 'participating'
      current_user.participating_conversations.where(account_id: current_account.id)
    when 'unattended'
      conversations.unattended
    else
      conversations
    end
  end

  def filter_by_query(conversations, query)
    return conversations unless query

    allowed_message_types = [Message.message_types[:incoming], Message.message_types[:outgoing]]
    conversations.joins(:messages).where('messages.content ILIKE :search', search: "%#{query}%")
                 .where(messages: { message_type: allowed_message_types }).includes(:messages)
                 .where('messages.content ILIKE :search', search: "%#{query}%")
                 .where(messages: { message_type: allowed_message_types })
  end

  def filter_by_status(conversations, status, default_status = 'open')
    return conversations if status == 'all'

    conversations.where(status: status || default_status)
  end

  def filter_by_team(conversations, team)
    return conversations unless team

    conversations.where(team: team)
  end

  def filter_by_labels(conversations, labels)
    return conversations unless labels

    conversations.tagged_with(labels, any: true)
  end

  def filter_by_source_id(conversations, source_id)
    return conversations unless source_id

    conversations.joins(:contact_inbox).where(contact_inboxes: { source_id: source_id })
  end

  def filter_by_updated_date(conversations, updated_within)
    return conversations if updated_within.blank?

    conversations.where(
      'conversations.updated_at > ?',
      Time.zone.now - updated_within.to_i.seconds
    )
  end

  def apply_sorting(conversations, sort_option, sort_options)
    sort_by, sort_order = sort_options[sort_option] || sort_options['last_activity_at_desc']
    conversations.send(sort_by, sort_order)
  end
end
