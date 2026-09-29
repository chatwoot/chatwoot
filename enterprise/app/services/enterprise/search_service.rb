module Enterprise::SearchService
  def available_types
    permissions = account_user.permissions
    return super if permissions.intersect?(%w[agent administrator])

    allowed = []
    allowed << 'contacts' if permissions.include?('contact_manage')
    allowed << 'articles' if permissions.include?('knowledge_base_manage')
    allowed.push('conversations', 'messages') if permissions.intersect?(%w[conversation_manage conversation_unassigned_manage
                                                                           conversation_participating_manage])
    super & allowed
  end

  def countable_types
    restricted_conversation_access? ? super - %w[conversations messages] : super
  end

  def advanced_search(count: false)
    where_conditions = build_where_conditions
    apply_filters(where_conditions)

    results = Message.search(
      search_query,
      fields: %w[content attachments.transcribed_text content_attributes.email.subject],
      where: where_conditions,
      **advanced_search_options(count: count)
    )
    return results.total_count if count
    return results.to_a unless restricted_conversation_access?

    scope = current_account.messages.where(conversation_id: accessible_conversations.select(:id))
    Search::PermissionScopedMessages.new(search: results, scope: scope).records(page: params[:page], per_page: page_size)
  end

  private

  def advanced_search_options(count:)
    return { limit: 0, load: false, body_options: { track_total_hits: true } } if count

    # id breaks created_at ties; unmapped_type supports older indexed documents.
    order = { created_at: :desc, id: { order: :desc, unmapped_type: 'long' } }
    return { order: order, page: params[:page] || 1, per_page: page_size } unless restricted_conversation_access?

    { order: order, limit: Search::PermissionScopedMessages::BATCH_SIZE, scroll: '1m', load: false, select: [] }
  end

  def message_base_query
    query = super
    restricted_conversation_access? ? query.where(conversation_id: accessible_conversations.select(:id)) : query
  end

  def restricted_conversation_access?
    permissions = account_user.permissions
    permissions.include?('custom_role') && permissions.exclude?('conversation_manage')
  end

  def build_where_conditions
    conditions = { account_id: current_account.id }
    conditions[:inbox_id] = accessable_inbox_ids unless should_skip_inbox_filtering?
    conditions
  end

  def apply_filters(where_conditions)
    apply_from_filter(where_conditions)
    apply_time_range_filter(where_conditions)
    apply_inbox_filter(where_conditions)
  end

  def apply_from_filter(where_conditions)
    sender_type, sender_id = parse_from_param(params[:from])
    return unless sender_type && sender_id

    where_conditions[:sender_type] = sender_type
    where_conditions[:sender_id] = sender_id
  end

  def parse_from_param(from_param)
    return [nil, nil] unless from_param&.match?(/\A(contact|agent):\d+\z/)

    type, id = from_param.split(':')
    sender_type = type == 'agent' ? 'User' : 'Contact'
    [sender_type, id.to_i]
  end

  def apply_time_range_filter(where_conditions)
    time_conditions = {}
    time_conditions[:gte] = enforce_time_limit(params[:since])
    time_conditions[:lte] = cap_until_time(params[:until]) if params[:until].present?

    where_conditions[:created_at] = time_conditions if time_conditions.any?
  end

  def cap_until_time(until_param)
    max_future = 90.days.from_now
    requested_time = Time.zone.at(until_param.to_i)

    [requested_time, max_future].min
  end

  def enforce_time_limit(since_param)
    max_lookback = Limits::MESSAGE_SEARCH_TIME_RANGE_LIMIT_DAYS.days.ago

    if since_param.present?
      requested_time = Time.zone.at(since_param.to_i)
      # Silently cap to max_lookback if requested time is too far back
      [requested_time, max_lookback].max
    else
      max_lookback
    end
  end

  def apply_inbox_filter(where_conditions)
    return if params[:inbox_id].blank?

    inbox_id = params[:inbox_id].to_i
    return if inbox_id.zero?
    return unless validate_inbox_access(inbox_id)

    where_conditions[:inbox_id] = inbox_id
  end

  def validate_inbox_access(inbox_id)
    return true if should_skip_inbox_filtering?

    accessable_inbox_ids.include?(inbox_id)
  end
end
