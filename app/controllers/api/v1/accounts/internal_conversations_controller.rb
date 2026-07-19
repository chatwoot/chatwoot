class Api::V1::Accounts::InternalConversationsController < Api::V1::Accounts::BaseController
  before_action :ensure_internal_chats_enabled
  before_action :fetch_conversation, only: [:show, :messages, :create_message]

  def index
    authorize(InternalConversation)
    ensure_rooms_for_memberships!
    @internal_conversations = policy_scope(InternalConversation)
                                .includes(team: :members)
                                .order(Arel.sql('last_activity_at DESC NULLS LAST'), :id)
  end

  def show
    authorize @internal_conversation
  end

  def messages
    authorize @internal_conversation, :show?
    messages = @internal_conversation.internal_messages.includes(:user).order(id: :desc).limit(50)
    messages = messages.where('id < ?', params[:before_id].to_i) if params[:before_id].present?
    @internal_messages = messages
  end

  def create_message
    authorize @internal_conversation, :create_message?
    @internal_message = @internal_conversation.internal_messages.create!(
      account: Current.account,
      user: Current.user,
      content: message_content
    )
    render :create_message, status: :created
  end

  private

  def ensure_internal_chats_enabled
    # Account feature is source of truth; INTERNAL_CHATS_ENABLED is a temporary global kill-switch.
    account_enabled = Current.account.feature_enabled?('internal_chats')
    global_enabled = ActiveModel::Type::Boolean.new.cast(
      GlobalConfigService.load('INTERNAL_CHATS_ENABLED', 'false')
    )
    return if account_enabled && global_enabled

    render json: { error: 'Feature not enabled' }, status: :forbidden
  end

  def fetch_conversation
    @internal_conversation = policy_scope(InternalConversation)
                               .includes(team: :members)
                               .find(params[:id])
  end

  def ensure_rooms_for_memberships!
    teams = if Current.account_user.administrator?
              Current.account.teams
            else
              Current.user.teams.where(account_id: Current.account.id)
            end

    teams.find_each do |team|
      InternalConversation.ensure_for!(account: Current.account, team: team)
    end
  end

  def message_content
    params.require(:content).to_s
  end
end
