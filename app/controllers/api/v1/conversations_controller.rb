class Api::V1::ConversationsController < Api::BaseController
  before_action :set_conversation, except: [:index]

  def index
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def show; end

  def toggle_status
    @status = @conversation.toggle_status
  end

  def update_last_seen
    @conversation.agent_last_seen_at = parsed_last_seen_at
    @conversation.save!
    head :ok
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
end
