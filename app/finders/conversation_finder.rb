class ConversationFinder
  attr_reader :current_user, :current_account, :params

  DEFAULT_STATUS = 'open'.freeze

  # assumptions
  # inbox_id if not given, take from all conversations, else specific to inbox
  # assignee_type if not given, take 'all'
  # conversation_status if not given, take 'open'

  # response of this class will be of type
  # {conversations: [array of conversations], count: {open: count, resolved: count}}

  # params
  # assignee_type, inbox_id, :status

  def initialize(current_user, params)
    @current_user = current_user
    @current_account = current_user.account
    @params = params
  end

  def perform
    set_inboxes
    set_team
    set_assignee_type

    find_all_conversations
    filter_by_status unless params[:q]
    filter_by_team if @team
    filter_by_labels if params[:labels]
    filter_by_query if params[:q]

    mine_count, unassigned_count, all_count = set_count_for_all_conversations

    filter_by_assignee_type

    {
      conversations: conversations,
      count: {
        mine_count: mine_count,
        unassigned_count: unassigned_count,
        all_count: all_count
      }
    }
  end

  private

  def set_inboxes
    if params[:inbox_id]
      @inbox_ids = current_account.inboxes.where(id: params[:inbox_id])
    else
      if @current_user.administrator?
        @inbox_ids = current_account.inboxes.pluck(:id)
      elsif @current_user.agent?
        @inbox_ids = @current_user.assigned_inboxes.pluck(:id)
      end
    end
  end

  def set_assignee_type
    @assignee_type = params[:assignee_type]
  end

  def set_team
    @team = current_account.teams.find(params[:team_id]) if params[:team_id]
  end

  def find_all_conversations
    @conversations = current_account.conversations.where(inbox_id: @inbox_ids)
  end

  def filter_by_assignee_type
    case @assignee_type
    when 'me'
      @conversations = @conversations.assigned_to(current_user)
    when 'unassigned'
      @conversations = @conversations.unassigned
    end
    @conversations
  end

  def filter_by_query
    allowed_message_types = [Message.message_types[:incoming], Message.message_types[:outgoing]]
    @conversations = conversations.joins(:messages).where('messages.content ILIKE :search', search: "%#{params[:q]}%")
                                  .where(messages: { message_type: allowed_message_types }).includes(:messages)
                                  .where('messages.content ILIKE :search', search: "%#{params[:q]}%")
                                  .where(messages: { message_type: allowed_message_types })
  end

  def filter_by_status
    @conversations = @conversations.where(status: params[:status] || DEFAULT_STATUS)
  end

  def filter_by_team
    @conversations = @conversations.where(team: @team)
  end

  def filter_by_labels
    @conversations = @conversations.tagged_with(params[:labels], any: true)
  end

  def set_count_for_all_conversations
    [
      @conversations.assigned_to(current_user).count,
      @conversations.unassigned.count,
      @conversations.count
    ]
  end

  def current_page
    params[:page]
  end

  def conversations
    @conversations = @conversations.includes(
      :taggings, :inbox, { assignee: { avatar_attachment: [:blob] } }, { contact: { avatar_attachment: [:blob] } }
    )
    current_page ? @conversations.latest.page(current_page) : @conversations.latest
  end
end
