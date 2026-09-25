class Api::V1::Accounts::Contacts::ConversationsController < Api::V1::Accounts::Contacts::BaseController
  RESULTS_PER_PAGE = 25

  # The in-thread navigation only needs neighbours, not the list counts.
  before_action :set_counts, unless: -> { params[:conversation_id].present? }

  # Scoped to a conversation, this returns it with the ones created around it: the in-thread
  # navigation walks the whole history and never needs more than that.
  def index
    @conversations = if params[:conversation_id].present?
                       conversation_with_neighbours(params[:conversation_id])
                     else
                       permitted_conversations.order(last_activity_at: :desc, id: :desc).page(params[:page] || 1).per(RESULTS_PER_PAGE)
                     end
  end

  def filter
    @conversations = Contacts::ConversationFilterService.new(
      params.permit!, Current.user, Current.account, contact: @contact
    ).perform[:conversations]
    render :index
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
  end

  private

  def permitted_conversations
    conversations = Current.account.conversations.includes(
      :assignee, :contact, :taggings, :contact_inbox
    ).preload(
      inbox: :channel,
      ai_assignee: { avatar_attachment: [:blob] }
    ).where(contact_id: @contact.id)

    Conversations::PermissionFilterService.new(
      conversations,
      Current.user,
      Current.account
    ).perform
  end

  def set_counts
    @all_count = permitted_conversations.count
    @open_count = permitted_conversations.open.count
  end

  def conversation_with_neighbours(display_id)
    conversation = permitted_conversations.find_by!(display_id: display_id)

    [neighbour(conversation, :older), conversation, neighbour(conversation, :newer)].compact
  end

  def neighbour(conversation, direction)
    comparison = direction == :older ? '<' : '>'
    order = direction == :older ? :desc : :asc

    permitted_conversations
      .where("(conversations.created_at, conversations.id) #{comparison} (?, ?)", conversation.created_at, conversation.id)
      .order(created_at: order, id: order)
      .first
  end
end
