class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController # rubocop:disable Metrics/ClassLength
  include Events::Types
  include DateRangeHelper
  include HmacConcern
  include ConversationCustomAttributesConcern
  include ConversationAssignmentTargetsConcern

  before_action :conversation, except: [:index, :meta, :sync, :search, :create, :filter, :presence_subscribe_bulk, :pins, :unpin]
  before_action :validate_assignment_targets, :inbox, :contact, :contact_inbox, only: [:create]

  ATTACHMENT_RESULTS_PER_PAGE = 100
  # One page of conversations, the same unit the index endpoint serializes at. The partial does
  # per-row work (unread counts, the last non-activity message), so an uncapped list would let any
  # authenticated agent ask one worker to render the whole account. The dashboard chunks to match,
  # and an oversized batch is refused rather than truncated: a truncated answer is indistinguishable
  # from "these conversations are gone" to a caller that reconciles against it.
  SYNC_BATCH_SIZE = 25
  # One debounced batch of inbound messages, generously. The whole thread is never the answer,
  # since a receipt per message of history empties a year of unread badges on the contact's
  # phone, so this holds both branches of the endpoint to the same reach.
  #
  # A named list over it is refused and a resolved one is truncated, which is not a
  # contradiction: naming 51 ids is a claim about what the caller processed, and no
  # conversation flow produces it, so answering it at all would be answering a mistake. The
  # default names nothing, and the newest is then the only sensible part to keep.
  READ_RECEIPT_BATCH_SIZE = 50

  def index
    result = conversation_finder.perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
  end

  def meta
    result = conversation_finder.perform_meta_only
    @conversations_count = result[:count]
  end

  # The current state of the conversations the caller names, and nothing else. The dashboard asks
  # when its own list is longer than the count the server reports for a tab, a contradiction it
  # cannot resolve on its own: nothing in the store ever removes a conversation that left a tab, so
  # a single missed cable event leaves a stale copy behind forever.
  #
  # Deliberately ignores every tab filter, and that is the whole point: the caller is asking what
  # these conversations ARE, and the ones it is asking after are precisely the ones that stopped
  # matching its filters. What comes back replaces the stale rows, so they leave the tab through
  # their own data while keeping whatever other tab they still belong to. Whatever does not come
  # back is gone for this agent, deleted or no longer permitted, and the caller drops it.
  #
  # POST, and scoped to the ids it was given, so the answer can never outgrow the question: the
  # count that triggers the ask can itself be stale (a debounced meta answering for the filter
  # before last), so the tab can be far larger than the handful the client has on screen.
  def sync
    ids = permitted_conversation_ids
    return render_could_not_create_error("ids must contain at most #{SYNC_BATCH_SIZE} entries") if ids.size > SYNC_BATCH_SIZE

    @conversations = conversation_finder.perform_sync(ids)
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

  def presence_subscribe_bulk
    Conversations::PresenceSubscribeService.new(Current.account, presence_subscribe_params[:conversation_ids]).perform
    head :ok
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

  # Pins belong to a User; agent bots never reach these actions, they are not in BOT_ACCESSIBLE_ENDPOINTS.
  #
  # Both checks the pin runs read state a concurrent request can change before the insert lands, and they
  # need different rows to serialize against: the agent's row for the per-user limit (same shape as
  # AgentBuilder's seat limit), the conversation's for the resolved check, since only that one blocks a
  # concurrent resolve from committing mid-flight. This is the only place that takes both, so the order
  # cannot invert.
  def pin
    pin = Current.user.with_lock do
      @conversation.with_lock do
        ConversationPin.prune_hidden(Current.user, Current.account)
        @conversation.conversation_pins.find_or_create_by!(user: Current.user)
      end
    end
    render json: { conversation_id: @conversation.display_id, pinned_at: pin.created_at.to_f }
  end

  # Looked up through the pin rather than the conversation, and deliberately not through `current_user_pins`:
  # removing your own pin never depends on still being able to see the conversation.
  def unpin
    Current.user.conversation_pins
           .where(account_id: Current.account.id)
           .joins(:conversation).where(conversations: { display_id: params[:id] })
           .destroy_all
    head :ok
  end

  # Joined, not just eager loaded: Conversation destroys its pins asynchronously, so between the row going
  # away and the job running, an orphaned pin would render `nil.display_id`.
  def pins
    @conversation_pins = current_user_pins.joins(:conversation).includes(:conversation)
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
    return toggle_status_if_expected if params.key?(:expected_status)
    return @conversation.bot_handoff! if bot_handoff?

    apply_toggle_status
  end

  # A caller that decided from a status it read earlier sends that status as `expected_status`, and the change applies
  # only while the conversation still holds it; otherwise nothing changes and the answer is 409 with the current status.
  # Without it a bot's `open` is a handoff on a pending conversation and a reopen on one an agent resolved meanwhile.
  # The row lock orders the check and the write against any other write to the conversation.
  def toggle_status_if_expected
    unless Conversation.statuses.key?(params[:expected_status])
      return render json: { error: 'expected_status is not a conversation status' }, status: :unprocessable_entity
    end

    handoff = false
    current = @conversation.with_lock do
      next @conversation.status if @conversation.status != params[:expected_status]

      handoff = bot_handoff?
      handoff ? @conversation.bot_handoff!(dispatch_event: false) : apply_toggle_status
      nil
    end
    return render json: { error: 'conversation status changed', current_status: current }, status: :conflict if current

    @conversation.dispatch_bot_handoff_event if handoff
  end

  def apply_toggle_status
    if params[:status].present?
      set_conversation_status
    else
      @conversation.status = @conversation.toggled_status
    end

    # Reopening self-assigns, and both changes have to land in the same save.
    # `previous_changes` only carries the last one, so saving twice would hide
    # the status change from every callback that reads `saved_change_to_status?`
    # (the reopen activity message, automations, reporting). Saving once also
    # means an inbox with `prevent_assignment_takeover` cannot answer 409 with
    # the conversation already reopened.
    handle_human_open if @conversation.open? && Current.user.is_a?(User)

    @status = @conversation.save!
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

  def presence_subscribe
    Conversations::PresenceSubscribeService.new(Current.account, [@conversation.display_id]).perform
    head :ok
  end

  def update_last_seen
    # High-traffic accounts generate excessive DB writes when agents frequently switch between conversations.
    # Throttle last_seen updates to once per hour when there are no unread messages to reduce DB load.
    # Always update immediately if there are unread messages to maintain accurate read/unread state.
    # Visiting a conversation should clear any unread inbox notifications for this conversation.
    Notification::MarkConversationReadService.new(user: Current.user, account: Current.account, conversation: @conversation).perform
    has_unread = assignee? ? @conversation.assignee_unread_messages.any? : @conversation.unread_messages.any?

    # No unread messages - apply throttling to limit DB writes
    return if !has_unread && !should_update_last_seen?

    dispatch_messages_read_event if assignee?

    update_last_seen_on_conversation(DateTime.now.utc, assignee?)
  end

  # Tells WhatsApp the contact's messages were read, and touches nothing else.
  #
  # Deliberately not `update_last_seen`. There the receipt is a side effect of a person
  # opening the thread, so it comes with `agent_last_seen_at`, the stamp that draws the
  # unread badge. An agent bot is not a person reading the thread: `bot_handoff!` hands
  # the conversation back to a human without rewinding that stamp, and one written here
  # would put it in their queue already looking read.
  #
  # The inbox's `mark_as_read` toggle still wins, downstream in Channel::Whatsapp, and a
  # channel with nothing to send a receipt through is a no-op, both as on the human path.
  def read_receipt
    authorize @conversation, :read_receipt?

    ids = permitted_message_ids
    if ids && ids.size > READ_RECEIPT_BATCH_SIZE
      return render_could_not_create_error("message_ids must contain at most #{READ_RECEIPT_BATCH_SIZE} entries")
    end

    messages = receipt_messages(ids)
    return head :ok if messages.empty?

    Rails.configuration.dispatcher.dispatch(Events::Types::MESSAGES_READ, Time.zone.now,
                                            conversation: @conversation, message_ids: messages.map(&:id))
    head :ok
  end

  def unread
    Rails.configuration.dispatcher.dispatch(Events::Types::CONVERSATION_UNREAD, Time.zone.now, conversation: @conversation)

    last_incoming_message = @conversation.messages.incoming.last
    last_seen_at = last_incoming_message.created_at - 1.second if last_incoming_message.present?
    update_last_seen_on_conversation(last_seen_at, true)
  end

  # Asks the phone for the page before the oldest message this thread holds.
  #
  # Scoped to the conversation because that is the shape of the thing being asked: the
  # provider walks one chat backwards from one anchor, and the operator asking is the one
  # reading that chat. Nothing here waits for messages -- the phone answers on the webhook
  # later, or never, so what the caller is told is that the request went out.
  def sync_history
    channel = @conversation.inbox.channel

    unless channel.try(:session_capabilities)&.include?('history_sync')
      render json: { error: 'Inbox does not support history sync' }, status: :unprocessable_entity and return
    end

    # The request travels to the phone through the session, so a closed one has nothing to
    # carry it and the operator would be told it was asked for nothing.
    unless channel.provider_connection.to_h['connection'] == 'open'
      render json: { error: 'Inbox is not connected' }, status: :unprocessable_entity and return
    end

    # Held for the providers that do not classify their frames: a Baileys answer identifies
    # itself as ON_DEMAND, uazapi's does not, and this is what tells that one somebody asked.
    Whatsapp::Session::HistoryBackfill.open!(channel)
    Whatsapp::Session::ConversationHistoryJob.perform_later(@conversation)
    head :ok
  end

  # Asks for every history file this conversation is still missing, whatever its age: the
  # inbox's automatic fetch stops at its window, and an old group is often the one somebody
  # needs. The files arrive as updates of their messages.
  def fetch_history_media
    unless @conversation.inbox.channel.try(:session_provider?)
      render json: { error: 'Inbox does not support history media' }, status: :unprocessable_entity and return
    end

    Whatsapp::Session::ConversationHistoryMediaJob.perform_later(@conversation)
    head :accepted
  end

  # Asked by the dashboard when it opens a conversation whose number was flagged as having no
  # WhatsApp. Only a flag older than the recheck window goes back to the provider, so opening
  # the same conversation again and again costs one lookup per window, not one per open. The
  # answer arrives as a conversation update.
  def recheck_whatsapp_number
    Whatsapp::NumberRecheckJob.perform_later(@conversation) if @conversation.contact_inbox&.whatsapp_missing_recheck_due?
    head :accepted
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

  def presence_subscribe_params
    params.permit(conversation_ids: [])
  end

  def update_last_seen_on_conversation(last_seen_at, update_assignee)
    updates = { agent_last_seen_at: last_seen_at }
    updates[:assignee_last_seen_at] = last_seen_at if update_assignee.present?

    # rubocop:disable Rails/SkipsModelValidations
    @conversation.update_columns(updates)
    # rubocop:enable Rails/SkipsModelValidations

    ::Conversations::UnreadCounts::Notifier.new(@conversation).perform
    ::Conversations::UnreadCounts::FilteredCountInvalidator.new(Current.account).conversation_changed!
  end

  def unseen_activity?
    @conversation.last_activity_at.present? &&
      (@conversation.agent_last_seen_at.blank? || @conversation.last_activity_at > @conversation.agent_last_seen_at)
  end

  def should_update_last_seen?
    # Always update when there's unseen activity (e.g. soft-disabled group conversations that don't create messages)
    return true if unseen_activity?

    # Update if at least one relevant timestamp is older than 1 hour or not set
    # This prevents redundant DB writes when agents repeatedly view the same conversation
    agent_needs_update = @conversation.agent_last_seen_at.blank? || @conversation.agent_last_seen_at < 1.hour.ago
    return agent_needs_update unless assignee?

    # For assignees, check both timestamps - update if either is old
    assignee_needs_update = @conversation.assignee_last_seen_at.blank? || @conversation.assignee_last_seen_at < 1.hour.ago
    agent_needs_update || assignee_needs_update
  end

  def set_conversation_status
    @conversation.status = params[:status]
    @conversation.snoozed_until = parse_date_time(params[:snoozed_until].to_s) if params[:snoozed_until]
  end

  # Only stages the change; `toggle_status` owns the save. Upstream locks and saves here, but the
  # status is already staged on the row by then, and a lock refuses a record with unsaved changes;
  # the single save is also what lets the 409 on a takeover answer before anything is reopened.
  def handle_human_open
    @conversation.ai_assignee = nil
    @conversation.assignee = Current.user if Current.user.agent?
  end

  def conversation
    @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])
    authorize @conversation, :show?
  end

  def current_user_pins
    ConversationPin.visible_to(Current.user, Current.account)
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
      hmac_verified: hmac_verified?,
      validate_whatsapp_phone: true
    ).perform
  end

  def conversation_finder
    @conversation_finder ||= ConversationFinder.new(Current.user, params)
  end

  def permitted_conversation_ids
    Array(params[:ids]).map(&:to_i)
  end

  # nil when the caller said nothing, which is what asks for the default window. An empty
  # array is not that: it is a caller naming no messages, and the answer to it is no receipt.
  # Collapsing the two acknowledges fifty messages for a debounced batch that came up empty,
  # which is the one thing this endpoint must never do on its own initiative.
  def permitted_message_ids
    return unless params.key?(:message_ids)

    Array(params[:message_ids]).map(&:to_i)
  end

  # The bot names the messages it processed -- a debounced batch is several -- or nothing, and
  # then the set is the unacknowledged part of a fixed window: the newest
  # READ_RECEIPT_BATCH_SIZE inbound messages of the thread, minus the ones already read.
  #
  # The window is over the thread, NOT over the unread ones, and that distinction is the
  # whole safety property. Taking the newest N *unread* rows looks equivalent and walks
  # backwards through history instead: the provider echoes each receipt back, the echo writes
  # `read` on those rows, and the next call's newest-N-unread is then the fifty before them.
  # A bot answers every message, so a thread with a year of history behind it gets paged
  # through fifty at a time until every badge on the contact's phone is gone. Anchored to the
  # thread, a message that was already old on the first call is never named on any call.
  #
  # The human path is not exposed to this because its watermark only moves forward. A bot
  # writes no watermark by design, so the window is what replaces it.
  #
  # Same size as the cap a caller-named list is held to: a default that reaches further than
  # a caller is allowed to name would be the wrong way round.
  #
  # Ordered by id as well as time, because the window is only fixed if it is deterministic.
  # Message's default scope orders by `created_at` alone, and an imported row carries the
  # timestamp WhatsApp gave it, which has second precision (`MessageWriter#build`): a burst
  # inside one second ties, Postgres is free to break the tie differently on the next call,
  # and the window drifts onto rows it had excluded -- the same walk backwards through
  # history the thread anchor exists to prevent, entered through the sort instead.
  def receipt_messages(ids)
    scope = @conversation.messages.incoming
    return scope.where.not(status: :read).where(id: ids).to_a if ids

    scope.reorder(created_at: :asc, id: :asc).last(READ_RECEIPT_BATCH_SIZE).reject { |message| message.status == 'read' }
  end

  def assignee?
    @conversation.assignee_id? && Current.user == @conversation.assignee
  end

  def dispatch_messages_read_event
    # NOTE: Use old `agent_last_seen_at`, so we reference messages received after that
    Rails.configuration.dispatcher.dispatch(Events::Types::MESSAGES_READ, Time.zone.now, conversation: @conversation,
                                                                                         last_seen_at: @conversation.agent_last_seen_at)
  end
end

Api::V1::Accounts::ConversationsController.prepend_mod_with('Api::V1::Accounts::ConversationsController')
