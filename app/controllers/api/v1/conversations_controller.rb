class Api::V1::ConversationsController < Api::BaseController
  before_action :set_conversation, except: [:index, :get_messages]

  # TODO: move this to public controller
  skip_before_action :authenticate_user!, only: [:get_messages]
  skip_before_action :set_current_user, only: [:get_messages]
  skip_before_action :check_subscription, only: [:get_messages]
  skip_around_action :handle_with_exception, only: [:get_messages]

  def index
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def show
    @messages = messages_finder.perform
  end

  def toggle_status
    @status = @conversation.toggle_status
  end

  def update_last_seen
    @conversation.agent_last_seen_at = parsed_last_seen_at
    @conversation.save!
    head :ok
  end

  def get_messages
    @conversation = Conversation.find(params[:id])
    @messages = messages_finder.perform
  end

  private

  def parsed_last_seen_at
    DateTime.strptime(params[:agent_last_seen_at].to_s, '%s')
  end

  def set_conversation
    @conversation ||= current_account.conversations.find_by(display_id: params[:id])
  end

  def conversation_finder
    @conversation_finder ||= ConversationFinder.new(current_user, params)
  end

  def messages_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end
end
