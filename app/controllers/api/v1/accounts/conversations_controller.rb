class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  include Events::Types
  include DateRangeHelper
  include HmacConcern
  include Api::V1::InboxesHelper

  before_action :conversation, except: [:index, :meta, :search, :create, :filter]
  before_action :inbox, :contact, :contact_inbox, only: [:create]

  ATTACHMENT_RESULTS_PER_PAGE = 100

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

  def attachments
    @attachments_count = @conversation.attachments.count
    @attachments = @conversation.attachments
                                .includes(:message)
                                .order(created_at: :desc)
                                .page(attachment_params[:page])
                                .per(ATTACHMENT_RESULTS_PER_PAGE)
  end

  def show; end

  def create
    ActiveRecord::Base.transaction do
      @conversation = ::ConversationBuilder.new(
        params: permitted_params.except(:contact_id),
        contact_inbox: @contact_inbox,
        user: current_user
      ).perform
    end
  end

  def update
    @conversation.update!(permitted_update_params)
  end

  def filter
    result = ::Conversations::FilterService.new(params.permit!, current_user, current_account).perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
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
    @conversation.toggle_status
    @status = @conversation.reload.status
  end

  def toggle_typing_status
    case params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON)
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF)
    end

    head :ok
  end

  def update_last_seen
    @conversation.agent_last_seen_at = parsed_last_seen_at
    @conversation.save!
    head :ok
  end

  def unread
    @conversation.unread!
    head :ok
  end

  def custom_attributes
    @conversation.custom_attributes = params[:custom_attributes]
    @conversation.save!
  end

  def content_attributes
    @conversation.content_attributes = permitted_content_attributes
    @conversation.save!
    render json: @conversation.content_attributes
  end

  def update_content_attributes
    case params[:section]
    when 'conversation_context'
      @conversation.track_conversation_context(params[:data])
    when 'resolution_context'
      @conversation.set_resolution_context(params[:data])
    when 'customer_satisfaction'
      @conversation.set_customer_satisfaction(params[:data])
    when 'interaction_patterns'
      @conversation.update_interaction_patterns
    else
      @conversation.content_attributes = @conversation.content_attributes.merge(params[:section] => params[:data])
    end
    
    @conversation.save!
    render json: @conversation.content_attributes
  end

  private

  def permitted_update_params
    # TODO: Move the other conversation attributes to this method and remove specific endpoints for each attribute
    params.permit(:priority)
  end

  def attachment_params
    params.permit(:page)
  end

  def trigger_typing_event(event)
    user = current_user.presence || @resource
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: user)
  end

  def conversation
    @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])
    authorize @conversation.inbox, :show?
  end

  def inbox
    return if params[:inbox_id].blank?

    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end

  def contact
    return if params[:contact_id].blank?

    @contact = Current.account.contacts.find(params[:contact_id])
  end

  def contact_inbox
    @contact_inbox = build_contact_inbox

    # fallback for the old case where we do look up only using source id
    # In future we need to change this and make sure we do look up on combination of inbox_id and source_id
    # and deprecate the support of passing only source_id as the param
    @contact_inbox ||= ::ContactInbox.find_by!(source_id: params[:source_id])
    authorize @contact_inbox.inbox, :show?
  rescue ActiveRecord::RecordNotUnique
    render json: { error: 'source_id should be unique' }, status: :unprocessable_entity
  end

  def build_contact_inbox
    return if @inbox.blank? || @contact.blank?

    ContactInboxBuilder.new(
      contact: @contact,
      inbox: @inbox,
      source_id: params[:source_id],
      hmac_verified: hmac_verified?
    ).perform
  end

  def conversation_finder
    @conversation_finder ||= ConversationFinder.new(current_user, params.permit(ConversationFinder::ALLOWED_PARAMS))
  end

  def permitted_params
    params.permit(
      :account_id, :inbox_id, :contact_id, :assignee_id, :team_id,
      :additional_attributes, :status, :priority, :snoozed_until, :content_attributes,
      message: [:content, :message_type, :private, :content_type, { content_attributes: {} }, { attachments: [] }],
      content_attributes: {}
    )
  end

  def permitted_content_attributes
    params.require(:content_attributes).permit!
  end

  def parsed_last_seen_at
    DateTime.strptime(params[:agent_last_seen_at].to_s, '%s')
  end
end

Api::V1::Accounts::ConversationsController.prepend_mod_with('Api::V1::Accounts::ConversationsController')
