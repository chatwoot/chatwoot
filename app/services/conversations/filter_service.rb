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
        all_count: all_count,
        missing_pages: missing_pages(mine_count, unassigned_count, all_count)
      }
    }
  end

  def base_relation
    conversations = @account.conversations.includes(
      :taggings, :inbox, { assignee: { avatar_attachment: [:blob] } }, { contact: { avatar_attachment: [:blob] } }, :team, :messages, :contact_inbox
    )

    Conversations::PermissionFilterService.new(
      conversations,
      @user,
      @account
    ).perform
  end

  def current_page
    @params[:page] || 1
  end

  def missing_pages(mine_count, unassigned_count, all_count)
    records_per_page = ENV.fetch('CONVERSATION_RESULTS_PER_PAGE', '25').to_i
    total_pages =
      case @params[:assignee_type]
      when 'me'
        (mine_count.to_f / records_per_page).ceil
      when 'unassigned'
        (unassigned_count.to_f / records_per_page).ceil
      else
        (all_count.to_f / records_per_page).ceil
      end

    total_pages.to_i - current_page.to_i
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
end
