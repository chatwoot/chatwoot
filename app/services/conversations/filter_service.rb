class Conversations::FilterService < FilterService
  ATTRIBUTE_MODEL = 'conversation_attribute'.freeze

  def initialize(params, user, account)
    @account = account
    super(params, user)
  end

  def perform
    validate_query_operator
    @conversations = query_builder(@filters['conversations'])
    mine_count, unassigned_count, all_count, = set_count_for_all_conversations
    assigned_count = all_count - unassigned_count

    {
      conversations: conversations,
      count: {
        mine_count: mine_count,
        assigned_count: assigned_count,
        unassigned_count: unassigned_count,
        all_count: all_count
      }
    }
  end

  def base_relation
    # :messages is deliberately not preloaded: the list payload fetches messages through
    # scoped queries (last message, last_non_activity_message), which bypass the preload.
    conversations = @account.conversations.includes(
      :taggings, :inbox, { assignee: { avatar_attachment: [:blob] } }, { contact: { avatar_attachment: [:blob] } }, :team, :contact_inbox
    ).preload(ai_assignee: { avatar_attachment: [:blob] })

    Conversations::PermissionFilterService.new(
      conversations,
      @user,
      @account,
      plan_hint_selective_filter: label_filter_present?
    ).perform
  end

  def current_page
    @params[:page] || 1
  end

  def filter_config
    {
      entity: 'Conversation',
      table_name: 'conversations'
    }
  end

  def conversations
    @conversations.sort_on_last_activity_at.page(current_page)
  end

  private

  # The planner hint only pays off when the label condition positively narrows the
  # result set: `equal_to` joined by AND. Negative/presence operators or an OR in the
  # payload leave the result broad, where the inbox index is the better driver.
  def label_filter_present?
    payload = @params[:payload].to_a
    return false if payload.any? { |query_hash| query_hash[:query_operator].to_s.casecmp('or').zero? }

    payload.any? { |query_hash| query_hash[:attribute_key] == 'labels' && query_hash[:filter_operator] == 'equal_to' }
  end
end
