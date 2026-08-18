class Api::V1::Accounts::Pathors::CallsController < Api::V1::Accounts::BaseController
  # Accepts both the Pathors backend vocabulary (inbound/outbound) and the
  # persisted one (incoming/outgoing) so either side can evolve independently.
  DIRECTIONS = {
    'inbound' => 'incoming',
    'incoming' => 'incoming',
    'outbound' => 'outgoing',
    'outgoing' => 'outgoing'
  }.freeze

  # create/update are backend-to-backend webhooks: bots use the whitelisted bot
  # token (see BOT_ACCESSIBLE_ENDPOINTS), agents their own token. `join` is a
  # dashboard action authorized on conversation access (see #authorize_join).
  before_action :fetch_conversation, only: [:create]
  before_action :fetch_call, only: [:update]
  before_action :fetch_pathors_call, only: [:join]
  before_action :authorize_join, only: [:join]

  def create
    direction = DIRECTIONS[create_params[:direction].to_s]
    return render_error('Invalid direction') if direction.blank?

    status = normalized_status(create_params[:status].presence || 'in_progress')
    return render_error('Invalid status') if status.blank?

    existing = existing_call
    return render_call(existing) if existing.present?

    render_call(create_call_with_message(direction, status))
  rescue ActiveRecord::RecordNotUnique
    # Lost a create race on (provider, provider_call_id) — the winner's row is
    # the idempotent answer, same as if it had existed before the check.
    render_call(existing_call)
  end

  def update
    return render_error('Invalid recording_url') if invalid_recording_url?

    stale_status? ? apply_recording_url : apply_update

    render_call(@call)
  end

  # Hands the clicking agent a LiveKit token for the room the voice agent is
  # already in. The Pathors backend arbitrates who wins the race (409) and
  # whether the call is still alive (404); we relay its answer as-is.
  def join
    return render json: { error: 'call_ended' }, status: :gone if @call.terminal?

    result = ::Pathors::CallJoinService.new(call: @call, user: Current.user).perform
    record_join if result.ok?

    render json: result.body, status: result.status
  end

  private

  def record_join
    @call.update(accepted_by_agent_id: Current.user.id)
    # Rebroadcasts the bubble so every other dashboard sees who answered.
    # rubocop:disable Rails/SkipsModelValidations
    @call.message&.touch
    # rubocop:enable Rails/SkipsModelValidations
    assign_conversation_to_joiner
  end

  # Answering an unassigned conversation claims it, mirroring what a human
  # picking up a phone means. An existing assignee is never overwritten.
  def assign_conversation_to_joiner
    conversation = @call.conversation
    return if conversation.blank?
    return if conversation.assignee_id.present? || conversation.assignee_agent_bot_id.present?

    ::Conversations::AssignmentService.new(conversation: conversation, assignee_id: Current.user.id).perform
  end

  def create_call_with_message(direction, status)
    ActiveRecord::Base.transaction do
      call = build_call(direction, status)
      message = build_message(direction)
      call.update!(message_id: message.id)
      call
    end
  end

  def build_call(direction, status)
    Call.create!(
      account: Current.account,
      inbox: @conversation.inbox,
      conversation: @conversation,
      contact: @conversation.contact,
      provider: :pathors,
      provider_call_id: create_params[:provider_call_id],
      direction: direction,
      status: status,
      started_at: Call.normalize_timestamp(create_params[:started_at]) || Time.current,
      from_number: create_params[:from_number],
      to_number: create_params[:to_number]
    )
  end

  def build_message(direction)
    inbound = direction == 'incoming'
    @conversation.messages.create!(
      account: Current.account,
      inbox: @conversation.inbox,
      message_type: inbound ? :incoming : :outgoing,
      content: 'Voice call',
      content_type: 'voice_call',
      sender: inbound ? @conversation.contact : nil
    )
  end

  # A call that already reached a terminal state must never be walked back to a
  # live one by a late/out-of-order webhook.
  def stale_status?
    status = normalized_status(update_params[:status])
    status.present? && @call.terminal? && Call::TERMINAL_STATUSES.exclude?(status)
  end

  # The recording is uploaded only after the platform finalizes the call, so it
  # necessarily arrives later than the terminal status. It is therefore the one
  # field a stale-status webhook may still carry that is worth keeping — the
  # guard exists to block status regressions, not to block the recording.
  def apply_recording_url
    return if update_params[:recording_url].blank?

    persist(recording_url: update_params[:recording_url])
  end

  def apply_update
    attributes = update_params.slice(:duration_seconds, :end_reason, :ended_at, :recording_url).to_h
    status = normalized_status(update_params[:status])
    attributes[:status] = status if status.present?

    persist(attributes)
  end

  def persist(attributes)
    @call.update!(attributes)
    # Fires MESSAGE_UPDATED so the dashboard bubble re-renders with the new state.
    # rubocop:disable Rails/SkipsModelValidations
    @call.message&.touch
    # rubocop:enable Rails/SkipsModelValidations
  end

  # The dashboard hands this straight to an <audio> element, so anything that is
  # not a fetchable http(s) URL is a caller bug rather than something to store.
  def invalid_recording_url?
    value = update_params[:recording_url]
    return false if value.blank?

    !URI.parse(value).is_a?(URI::HTTP)
  rescue URI::InvalidURIError
    true
  end

  def existing_call
    account_calls.find_by(provider: :pathors, provider_call_id: create_params[:provider_call_id])
  end

  # Account has no `calls` association upstream; scope explicitly rather than
  # adding one, to keep this feature contained to its own files.
  def account_calls
    Call.where(account_id: Current.account.id)
  end

  def fetch_conversation
    @conversation = Current.account.conversations.find_by!(display_id: create_params[:conversation_id])
  end

  def fetch_call
    @call = account_calls.find(params[:id])
  end

  # A non-pathors call has no LiveKit room to join, so it is simply not found
  # for this endpoint rather than a distinct error the UI has to phrase.
  def fetch_pathors_call
    @call = account_calls.where(provider: :pathors).find(params[:id])
  end

  # Same bar as opening the conversation in the dashboard: any agent with inbox
  # or team access may answer, not just administrators.
  def authorize_join
    authorize @call.conversation, :show?
  end

  # Tolerates the dashed display form ('in-progress') the dashboard uses.
  def normalized_status(value)
    return nil if value.blank?

    candidate = value.to_s.tr('-', '_')
    Call::STATUSES.include?(candidate) ? candidate : nil
  end

  def render_call(call)
    render json: call.push_event_data.merge(message_id: call.message_id), status: :ok
  end

  def render_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def create_params
    params.permit(:conversation_id, :provider_call_id, :direction, :status, :from_number, :to_number, :started_at)
  end

  def update_params
    params.permit(:status, :duration_seconds, :end_reason, :ended_at, :recording_url)
  end
end
