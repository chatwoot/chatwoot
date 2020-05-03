class Api::V1::Accounts::ConversationsController < Api::BaseController
  before_action :conversation, except: [:index]
  before_action :contact_inbox, only: [:create]

  def index
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def meta
    result = conversation_finder.perform
    @conversations_count = result[:count]
  end

  def create
    @conversation = ::Conversation.create!(conversation_params)
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

  def conversation
    @conversation ||= current_account.conversations.find_by(display_id: params[:id])
  end

  def contact_inbox
    @contact_inbox ||= ::ContactInbox.find_by!(source_id: params[:source_id])
  end

  def conversation_params
    {
      account_id: current_account.id,
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def conversation_finder
    @conversation_finder ||= ConversationFinder.new(current_user, params)
  end
end
