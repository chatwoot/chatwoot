module Enterprise::SearchService
  def advanced_search
    where_conditions = build_where_conditions
    apply_filters(where_conditions)

    Message.search(
      search_query,
      fields: %w[content attachments.transcribed_text content_attributes.email.subject],
      where: where_conditions,
      # id breaks created_at ties so results stay stable across page fetches;
      # unmapped_type covers documents indexed before id was added
      order: { created_at: :desc, id: { order: :desc, unmapped_type: 'long' } },
      page: params[:page] || 1,
      per_page: 15
    )
  end

  private

  def filter_messages_with_like
    return super unless restricted_conversation_access? && current_account.feature_enabled?('advanced_search')

    filter_restricted_messages_with_like
  end

  def filter_restricted_messages_with_like
    apply_message_filters(message_base_query).joins(:conversation)
                                             .where(Messages::SearchTextCondition.new("%#{search_query}%").build)
                                             .reorder(created_at: :desc, id: :desc)
                                             .page(params[:page])
                                             .per(15)
  end

  def should_run_advanced_search?
    super && !restricted_conversation_access?
  end

  def permission_filter_required?
    super || restricted_conversation_access?
  end

  def restricted_conversation_access?
    account_user&.agent? && account_user.custom_role_id.present? && account_user.permissions.exclude?('conversation_manage')
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
