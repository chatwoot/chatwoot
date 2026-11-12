module Enterprise::SearchService
  # ID breaks created_at ties. The unmapped type also allows searches on older indices.
  MESSAGE_ORDER = { created_at: :desc, id: { order: :desc, unmapped_type: 'long' }.freeze }.freeze

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

  def supports_message_cursor?
    search_type.in?(%w[all Message]) && restricted_conversation_access? &&
      available_types.include?('messages') && should_run_advanced_search? && !use_gin_search
  end

  def advanced_search(count: false)
    where_conditions = build_where_conditions
    apply_filters(where_conditions)
    return restricted_advanced_search(where_conditions) if !count && restricted_conversation_access?

    results = indexed_message_search(where_conditions, **advanced_search_options(count: count))
    count ? results.total_count : results.to_a
  end

  private

  def advanced_search_options(count:)
    return { limit: 0, load: false, body_options: { track_total_hits: true } } if count

    { order: MESSAGE_ORDER, page: params[:page] || 1, per_page: page_size }
  end

  def indexed_message_search(where_conditions, **)
    Message.search(search_query, fields: %w[content attachments.transcribed_text content_attributes.email.subject], where: where_conditions, **)
  end

  def restricted_advanced_search(where_conditions)
    cursor = Search::MessageSearchCursor.new(current_account.id)
    continuation = cursor.read(params[:cursor])
    scope = current_account.messages.where(conversation_id: accessible_conversations.select(:id))
    search = ->(**options) { indexed_message_search(where_conditions, order: MESSAGE_ORDER, **options) }
    scanner = Search::PermissionScopedMessages.new(search: search, scope: scope)
    records = scanner.records(page: params[:page], per_page: page_size, continuation: continuation)
    @message_pagination = { next_cursor: cursor.write(after: scanner.next_sort, offset: scanner.remaining_offset) }
    records
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

  def enforce_time_limit(since_param)
    since_param.present? ? cap_since_time(since_param) : search_window_start
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
