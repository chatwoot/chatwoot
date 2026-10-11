class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  include Events::Types
  include DateRangeHelper
  include HmacConcern
  include ConversationCustomAttributesConcern
  include ConversationAssignmentTargetsConcern
  include ConversationReadStateConcern

  before_action :conversation, except: [:index, :meta, :search, :create, :filter]
  before_action :validate_assignment_targets, :inbox, :contact, :contact_inbox, only: [:create]

  ATTACHMENT_RESULTS_PER_PAGE = 100

  def index
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def meta
    result = conversation_finder.perform_meta_only
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
                                .includes({ file_attachment: :blob }, message: [:inbox, { sender: { avatar_attachment: :blob } }])
                                .order(created_at: :desc)
                                .page(attachment_params[:page])
                                .per(ATTACHMENT_RESULTS_PER_PAGE)
  end

  def show; end

  def create
    ActiveRecord::Base.transaction do
      @conversation = ConversationBuilder.new(params: params, contact_inbox: @contact_inbox).perform
      Messages::MessageBuilder.new(Current.user, @conversation, params[:message]).perform if params[:message].present?
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
    return render_payment_required('Email transcript is not available on your plan') unless @conversation.account.email_transcript_enabled?
    return head :too_many_requests unless @conversation.account.within_email_rate_limit?

    ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(@conversation, params[:email])&.deliver_later
    @conversation.account.increment_email_sent_count
    head :ok
  end

  def toggle_status
    # FIXME: move this logic into a service object
    if bot_handoff?
      @conversation.bot_handoff!
    elsif params[:status].present?
      set_conversation_status
      @status = @conversation.save!
    else
      @status = @conversation.toggle_status
    end
    handle_human_open if @conversation.open? && Current.user.is_a?(User)
  end

  def bot_handoff?
    return false unless Current.user.is_a?(AgentBot)

    @conversation.status == 'pending' && params[:status] == 'open'
  end

  def toggle_priority
    @conversation.toggle_priority(permitted_update_params[:priority])
    head :ok
  end

  def toggle_typing_status
    typing_status_manager = ::Conversations::TypingStatusManager.new(@conversation, Current.user, params)
    typing_status_manager.toggle_typing_status
    head :ok
  end

  def destroy
    authorize @conversation, :destroy?
    ::Conversations::DeleteService.new(conversation: @conversation, user: Current.user, ip: request.ip).perform
    head :ok
  end

  private

  def permitted_update_params
    # TODO: Move the other conversation attributes to this method and remove specific endpoints for each attribute
    raise ActionController::ParameterMissing, :priority unless params[:priority].nil? || Conversation.priorities.key?(params[:priority])

    params.permit(:priority)
  end

  def attachment_params
    params.permit(:page)
  end

  def set_conversation_status
    @conversation.status = params[:status]
    @conversation.snoozed_until = parse_date_time(params[:snoozed_until].to_s) if params[:snoozed_until]
  end

  def handle_human_open
    @conversation.with_lock do
      @conversation.ai_assignee = nil
      @conversation.assignee = Current.user if Current.user.agent?
      @conversation.save!
    end
  end

  def conversation
    @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])
    authorize @conversation, :show?
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
    lookup_scope = @inbox ? @inbox.contact_inboxes : ContactInbox.joins(:inbox).where(inboxes: { account_id: Current.account.id })
    @contact_inbox ||= lookup_scope.find_by!(source_id: params[:source_id])
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
