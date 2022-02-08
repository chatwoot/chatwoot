class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  include Events::Types
  include DateRangeHelper

  before_action :conversation, except: [:index, :meta, :search, :create, :filter]
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

  def search
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def create
    ActiveRecord::Base.transaction do
      @conversation = ::Conversation.create!(conversation_params)
      Messages::MessageBuilder.new(Current.user, @conversation, params[:message]).perform if params[:message].present?
    end
  end

  def show; end

  def filter
    result = ::Conversations::FilterService.new(params.permit!, current_user).perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def mute
    @conversation.mute!
    head :ok
  end

  def unmute
    @conversation.unmute!
    head :ok
  end

  def transcript
    render json: { error: 'email param missing' }, status: :unprocessable_entity and return if params[:email].blank?

    ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(@conversation, params[:email])&.deliver_later
    head :ok
  end

  def toggle_status
    if params[:status]
      set_conversation_status
      @status = @conversation.save!
    else
      @status = @conversation.toggle_status
    end
    assign_conversation if @conversation.status == 'open' && Current.user.is_a?(User) && Current.user&.agent?
  end

  def toggle_typing_status
    case params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON, params[:is_private])
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF, params[:is_private])
    end
    head :ok
  end

  def update_last_seen
    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_column(:agent_last_seen_at, DateTime.now.utc)
    @conversation.update_column(:assignee_last_seen_at, DateTime.now.utc) if assignee?
    # rubocop:enable Rails/SkipsModelValidations
  end

  def custom_attributes
    @conversation.custom_attributes = params.permit(custom_attributes: {})[:custom_attributes]
    @conversation.save!
  end

  private

  def set_conversation_status
    status = params[:status] == 'bot' ? 'pending' : params[:status]
    @conversation.status = status
    @conversation.snoozed_until = parse_date_time(params[:snoozed_until].to_s) if params[:snoozed_until]
  end

  def assign_conversation
    @agent = Current.account.users.find(current_user.id)
    @conversation.update_assignee(@agent)
  end

  def trigger_typing_event(event, is_private)
    user = current_user.presence || @resource
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: user, is_private: is_private)
  end

  def conversation
    @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])
    authorize @conversation.inbox, :show?
  end

  def contact_inbox
    @contact_inbox = build_contact_inbox

    @contact_inbox ||= ::ContactInbox.find_by!(source_id: params[:source_id])
    authorize @contact_inbox.inbox, :show?
  end

  def build_contact_inbox
    return if params[:contact_id].blank? || params[:inbox_id].blank?

    inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize inbox, :show?

    ContactInboxBuilder.new(
      contact_id: params[:contact_id],
      inbox_id: inbox.id,
      source_id: params[:source_id]
    ).perform
  end

  def conversation_params
    additional_attributes = params[:additional_attributes]&.permit! || {}
    custom_attributes = params[:custom_attributes]&.permit! || {}
    status = params[:status].present? ? { status: params[:status] } : {}

    # TODO: temporary fallback for the old bot status in conversation, we will remove after couple of releases
    status = { status: 'pending' } if status[:status] == 'bot'
    {
      account_id: Current.account.id,
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: additional_attributes,
      custom_attributes: custom_attributes,
      snoozed_until: params[:snoozed_until],
      assignee_id: params[:assignee_id],
      team_id: params[:team_id]
    }.merge(status)
  end

  def conversation_finder
    @conversation_finder ||= ConversationFinder.new(current_user, params)
  end

  def assignee?
    @conversation.assignee_id? && current_user == @conversation.assignee
  end
end
