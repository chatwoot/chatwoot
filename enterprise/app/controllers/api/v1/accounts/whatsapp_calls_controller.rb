class Api::V1::Accounts::WhatsappCallsController < Api::V1::Accounts::BaseController
  before_action :ensure_whatsapp_call_enabled
  before_action :set_whatsapp_call, only: [:show, :accept, :reject, :terminate, :upload_recording]

  def show
    render json: {
      id: @whatsapp_call.id,
      call_id: @whatsapp_call.call_id,
      status: @whatsapp_call.status,
      direction: @whatsapp_call.direction,
      conversation_id: @whatsapp_call.conversation_id,
      inbox_id: @whatsapp_call.inbox_id,
      message_id: @whatsapp_call.message_id,
      sdp_offer: @whatsapp_call.ringing? ? @whatsapp_call.sdp_offer : nil,
      ice_servers: @whatsapp_call.ice_servers,
      caller: caller_info
    }
  end

  def accept
    sdp_answer = params[:sdp_answer]
    return render json: { error: 'sdp_answer is required' }, status: :unprocessable_entity if sdp_answer.blank?

    wa_call = Whatsapp::CallService.new(wa_call: @whatsapp_call, agent: current_user).pre_accept_and_accept(sdp_answer)
    render json: { id: wa_call.id, status: wa_call.status, message_id: wa_call.message_id }
  rescue Whatsapp::CallErrors::NotRinging, Whatsapp::CallErrors::AlreadyAccepted => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL] accept failed: #{e.message}"
    render json: { error: 'Failed to accept call' }, status: :internal_server_error
  end

  def reject
    wa_call = Whatsapp::CallService.new(wa_call: @whatsapp_call, agent: current_user).reject
    render json: { id: wa_call.id, status: wa_call.status }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL] reject failed: #{e.message}"
    render json: { error: 'Failed to reject call' }, status: :internal_server_error
  end

  def terminate
    wa_call = Whatsapp::CallService.new(wa_call: @whatsapp_call, agent: current_user).terminate
    render json: { id: wa_call.id, status: wa_call.status }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL] terminate failed: #{e.message}"
    render json: { error: 'Failed to terminate call' }, status: :internal_server_error
  end

  def upload_recording
    return render json: { error: 'No recording file provided' }, status: :unprocessable_entity if params[:recording].blank?
    return render json: { error: 'Call is not ended' }, status: :unprocessable_entity unless @whatsapp_call.terminal?

    attach_recording_and_enqueue_transcription
    render json: { id: @whatsapp_call.id, status: 'uploaded' }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL] upload_recording failed: #{e.message}"
    render json: { error: 'Failed to upload recording' }, status: :internal_server_error
  end

  def initiate
    conversation = current_account.conversations.find(params[:conversation_id])
    error = validate_whatsapp_calling(conversation)
    return render json: { error: error }, status: :unprocessable_entity if error

    wa_call = create_outbound_call(conversation)
    message = Whatsapp::CallMessageBuilder.create!(conversation: conversation, wa_call: wa_call, user: current_user)
    wa_call.update!(message_id: message.id)
    render json: { status: 'calling', call_id: wa_call.call_id, id: wa_call.id, message_id: message.id }
  rescue Whatsapp::CallErrors::NoCallPermission
    handle_no_call_permission(conversation)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Conversation not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL] initiate failed: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def create_outbound_call(conversation)
    contact_phone = conversation.contact&.phone_number
    raise ArgumentError, 'Contact phone number not available' if contact_phone.blank?
    raise ArgumentError, 'sdp_offer is required' if params[:sdp_offer].blank?

    result = conversation.inbox.channel.provider_service.initiate_call(contact_phone.delete('+'), params[:sdp_offer])
    call_id = result.dig('calls', 0, 'id') || result['call_id']

    current_account.whatsapp_calls.create!(
      inbox: conversation.inbox, conversation: conversation,
      call_id: call_id, direction: 'outbound', status: 'ringing',
      meta: { sdp_offer: params[:sdp_offer] }
    )
  end

  def handle_no_call_permission(conversation)
    last_requested = conversation.additional_attributes&.dig('call_permission_requested_at')

    return render json: { status: 'permission_pending' } if last_requested.present? && Time.zone.parse(last_requested) > 5.minutes.ago

    contact_phone = conversation.contact.phone_number.delete('+')
    result = conversation.inbox.channel.provider_service.send_call_permission_request(contact_phone)
    return render json: { error: 'Failed to send call permission request' }, status: :unprocessable_entity unless result

    attrs = (conversation.additional_attributes || {}).merge('call_permission_requested_at' => Time.current.iso8601)
    conversation.update!(additional_attributes: attrs)
    render json: { status: 'permission_requested' }
  end

  def validate_whatsapp_calling(conversation)
    channel = conversation.inbox.channel
    return 'Calling is only supported on WhatsApp Cloud inboxes' unless channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
    return 'Calling is not enabled for this inbox' unless channel.provider_config['calling_enabled']

    nil
  end

  def ensure_whatsapp_call_enabled
    render_payment_required('WhatsApp calling is not enabled for this account') unless current_account.feature_enabled?('whatsapp_call')
  end

  def set_whatsapp_call
    @whatsapp_call = current_account.whatsapp_calls.find(params[:id])
    authorize @whatsapp_call.conversation, :show?
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Call not found' }, status: :not_found
  end

  def attach_recording_and_enqueue_transcription
    @whatsapp_call.recording.attach(params[:recording])
    Whatsapp::CallMessageBuilder.update_recording_url!(wa_call: @whatsapp_call)
    Whatsapp::CallTranscriptionJob.perform_later(@whatsapp_call.id)
  end

  def caller_info
    contact = @whatsapp_call.conversation&.contact
    return {} unless contact

    { name: contact.name, phone: contact.phone_number, avatar: contact.avatar_url }
  end
end
