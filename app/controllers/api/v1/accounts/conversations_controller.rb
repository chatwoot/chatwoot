# rubocop:disable Metrics/ClassLength
class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  include Events::Types
  include DateRangeHelper
  include HmacConcern

  before_action :conversation, except: [:index, :meta, :search, :create, :filter]
  before_action :inbox, :contact, :contact_inbox, only: [:create]

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
    @attachments = @conversation.attachments
  end

  # rubocop:disable Metrics/MethodLength
  def mark_intent
    intent = params[:intent]
    # intent is a string like "PRE_SALES" or "SUPPORT"
    @conversation.update({
                           additional_attributes: @conversation.additional_attributes.merge(
                             intent: intent,
                             intent_created: Time.current
                           )
                         })

    if intent == 'PRE_SALES'
      @conversation.update_labels(@conversation.label_list - ['support-query'])
      Label.find_or_create_by!(
        account: Current.account,
        title: 'pre-sale-query'
      ) do |l|
        l.description = 'Automatically added to conversations with PRE_SALES intent'
        l.color = '#1f93ff' # Default color
      end
      @conversation.add_labels(['pre-sale-query'])
    elsif intent == 'SUPPORT'
      @conversation.update_labels(@conversation.label_list - ['pre-sale-query'])
      Label.find_or_create_by!(
        account: Current.account,
        title: 'support-query'
      ) do |l|
        l.description = 'Automatically added to conversations with SUPPORT intent'
        l.color = '#1f93ff' # Default color
      end
      @conversation.add_labels(['support-query'])
    end
    head :ok
  end
  # rubocop:enable Metrics/MethodLength

  def update_source_context
    existing_source_context = @conversation.additional_attributes[:source_context] || {}
    permitted_source_context = params.require(:source_context).permit!.to_h

    @conversation.update(
      additional_attributes: @conversation.additional_attributes.merge(
        source_context: existing_source_context.merge(permitted_source_context),
        nudge_created: Time.current
      )
    )
    head :ok
  end

  def show; end

  def create
    Rails.logger.info('Starting conversation creation process')
    previous_conversation = find_previous_conversation if params[:populate_historical_messages] == 'true'

    ActiveRecord::Base.transaction do
      create_conversation_and_initial_message
    end

    if previous_conversation.present? && @conversation.present? && params[:populate_historical_messages] == 'true'
      ConversationImport.perform_later(@conversation.id,
                                       previous_conversation.id)
    end

    Rails.logger.info('Completed conversation creation process:')
    @conversation = find_previous_conversation
    @conversation
  end

  def update
    @conversation.update!(permitted_update_params)
  end

  def filter
    result = ::Conversations::FilterService.new(params.permit!, current_user).perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
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
    # FIXME: move this logic into a service object
    if pending_to_open_by_bot?
      @conversation.bot_handoff!
    elsif params[:status].present?
      set_conversation_status
      @status = @conversation.save!
    else
      @status = @conversation.toggle_status
    end
    assign_conversation if should_assign_conversation?
  end

  def pending_to_open_by_bot?
    return false unless Current.user.is_a?(AgentBot)

    @conversation.status == 'pending' && params[:status] == 'open'
  end

  def should_assign_conversation?
    @conversation.status == 'open' && Current.user.is_a?(User) && Current.user&.agent?
  end

  def toggle_priority
    @conversation.toggle_priority(params[:priority])
    head :ok
  end

  def toggle_typing_status
    typing_status_manager = ::Conversations::TypingStatusManager.new(@conversation, current_user, params)
    typing_status_manager.toggle_typing_status
    head :ok
  end

  def update_last_seen
    update_last_seen_on_conversation(DateTime.now.utc, assignee?)
  end

  def unread
    last_incoming_message = @conversation.messages.incoming.last
    last_seen_at = last_incoming_message.created_at - 1.second if last_incoming_message.present?
    update_last_seen_on_conversation(last_seen_at, true)
  end

  def custom_attributes
    @conversation.custom_attributes = params.permit(custom_attributes: {})[:custom_attributes]
    @conversation.save!
  end

  private

  def create_conversation_and_initial_message
    @conversation = ConversationBuilder.new(params: params, contact_inbox: @contact_inbox).perform
    Rails.logger.info("Created new conversation: #{@conversation.id}")

    return if params[:message].blank?

    Messages::MessageBuilder.new(Current.user, @conversation, params[:message]).perform
    Rails.logger.info("Added initial message to conversation: #{@conversation.id}")
  end

  def find_previous_conversation
    Conversation.where(
      account_id: Current.account.id,
      inbox_id: params[:inbox_id],
      contact_id: params[:contact_id]
    ).order(created_at: :desc).first
  end

  def permitted_update_params
    # TODO: Move the other conversation attributes to this method and remove specific endpoints for each attribute
    params.permit(:priority)
  end

  def update_last_seen_on_conversation(last_seen_at, update_assignee)
    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_column(:agent_last_seen_at, last_seen_at)
    @conversation.update_column(:assignee_last_seen_at, last_seen_at) if update_assignee.present?
    # rubocop:enable Rails/SkipsModelValidations
  end

  def set_conversation_status
    @conversation.status = params[:status]
    @conversation.snoozed_until = parse_date_time(params[:snoozed_until].to_s) if params[:snoozed_until]
  end

  def assign_conversation
    @conversation.assignee = current_user
    @conversation.save!
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
    @conversation_finder ||= ConversationFinder.new(Current.user, params)
  end

  def assignee?
    @conversation.assignee_id? && Current.user == @conversation.assignee
  end
end

Api::V1::Accounts::ConversationsController.prepend_mod_with('Api::V1::Accounts::ConversationsController')
# rubocop:enable Metrics/ClassLength
