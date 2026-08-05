class Api::V1::Accounts::Pathors::CallsController < Api::V1::Accounts::BaseController
  # Accepts both the Pathors backend vocabulary (inbound/outbound) and the
  # persisted one (incoming/outgoing) so either side can evolve independently.
  DIRECTIONS = {
    'inbound' => 'incoming',
    'incoming' => 'incoming',
    'outbound' => 'outgoing',
    'outgoing' => 'outgoing'
  }.freeze

  before_action :check_admin_authorization?
  before_action :fetch_conversation, only: [:create]
  before_action :fetch_call, only: [:update]

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
    apply_update unless ignore_update?

    render_call(@call)
  end

  private

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
  def ignore_update?
    status = normalized_status(update_params[:status])
    status.present? && @call.terminal? && Call::TERMINAL_STATUSES.exclude?(status)
  end

  def apply_update
    attributes = update_params.slice(:duration_seconds, :end_reason, :ended_at).to_h
    status = normalized_status(update_params[:status])
    attributes[:status] = status if status.present?

    @call.update!(attributes)
    # Fires MESSAGE_UPDATED so the dashboard bubble re-renders with the new state.
    # rubocop:disable Rails/SkipsModelValidations
    @call.message&.touch
    # rubocop:enable Rails/SkipsModelValidations
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
    params.permit(:status, :duration_seconds, :end_reason, :ended_at)
  end
end
