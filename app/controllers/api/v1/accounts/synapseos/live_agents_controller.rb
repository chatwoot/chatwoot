class Api::V1::Accounts::Synapseos::LiveAgentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_user, only: [:conversations]

  def index
    @agents = ::Synapseos::LiveAgentsMetricsService.new(Current.account).call
  end

  def conversations
    @conversations = Current.account.conversations
                            .where(assignee_id: @user.id)
                            .includes(:contact)
                            .order(last_activity_at: :desc)
                            .limit(50)
    @last_messages_by_conversation = preload_last_messages(@conversations)
  end

  private

  def set_user
    @user = Current.account.users.find(params[:id])
  end

  # Evita N+1 pulando `conversation.messages.chat.last` por linha: 2 queries totais.
  def preload_last_messages(conversations)
    conversation_ids = conversations.map(&:id)
    return {} if conversation_ids.empty?

    last_ids = Message.where(conversation_id: conversation_ids).chat
                      .group(:conversation_id).maximum(:id)
    messages_by_id = Message.where(id: last_ids.values).index_by(&:id)
    last_ids.transform_values { |msg_id| messages_by_id[msg_id] }
  end

  def check_authorization
    authorize(User, :index?)
  end
end
