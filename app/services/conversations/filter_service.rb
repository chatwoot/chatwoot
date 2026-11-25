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
      :taggings, { assignee: { avatar_attachment: [:blob] } }, { contact: { avatar_attachment: [:blob] } }, :team,
      :contact_inbox
    ).preload(
      inbox: :channel,
      ai_assignee: { avatar_attachment: [:blob] }
    )

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

  # Folders and ad-hoc filters go through here, and until now they ignored `sort_by`
  # entirely: the list came back newest-first no matter what the agent picked, while the
  # ordinary conversation list (ConversationFinder) honoured ten different orders. The
  # sort control is hidden in that view, so the disagreement was invisible rather than
  # broken-looking, and a team working a folder oldest-first had no way to ask for it.
  #
  # SORT_OPTIONS is reused rather than redefined so the two paths cannot drift: one
  # allowlist, one set of names, and an unknown value falls back to the previous default
  # instead of reaching `send` (the params here are `permit!`ed straight from the request).
  def conversations
    # `pinned_first_for` orders too, and every sort_on_* uses `order` rather than
    # `reorder`, so pinned conversations keep leading the list in every order. That is the
    # existing behaviour of the ordinary list and it stays true here.
    Conversations::SortService.apply(@conversations.pinned_first_for(@user), @params[:sort_by]).page(current_page).per(per_page)
  end

  def per_page
    default = ENV.fetch('CONVERSATION_RESULTS_PER_PAGE', '25').to_i
    requested = (@params[:per_page] || default).to_i
    [requested, 100].min
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
