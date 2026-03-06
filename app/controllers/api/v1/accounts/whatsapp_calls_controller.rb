class Api::V1::Accounts::WhatsappCallsController < Api::V1::Accounts::BaseController
  before_action :set_whatsapp_call, only: [:accept, :reject, :terminate]

  def accept
    sdp_answer = params[:sdp_answer]
    return render json: { error: 'sdp_answer is required' }, status: :unprocessable_entity if sdp_answer.blank?

    wa_call = Whatsapp::CallService.new(wa_call: @whatsapp_call, agent: current_user).pre_accept_and_accept(sdp_answer)
    render json: { id: wa_call.id, status: wa_call.status }
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

  def initiate
    conversation = current_account.conversations.find(params[:conversation_id])
    error = validate_whatsapp_calling(conversation)
    return render json: { error: error }, status: :unprocessable_entity if error

    contact_phone = conversation.contact&.phone_number
    return render json: { error: 'Contact phone number not available' }, status: :unprocessable_entity if contact_phone.blank?

    result = conversation.inbox.channel.provider_service.initiate_call(contact_phone.delete('+'))
    return render json: { error: 'Failed to initiate call' }, status: :internal_server_error unless result

    render json: { status: 'calling', call_id: result['call_id'] }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Conversation not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL] initiate failed: #{e.message}"
    render json: { error: 'Failed to initiate call' }, status: :internal_server_error
  end

  private

  def validate_whatsapp_calling(conversation)
    channel = conversation.inbox.channel
    return 'Calling is only supported on WhatsApp Cloud inboxes' unless channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
    return 'Calling is not enabled for this inbox' unless channel.provider_config['calling_enabled']

    nil
  end

  def set_whatsapp_call
    @whatsapp_call = current_account.whatsapp_calls.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Call not found' }, status: :not_found
  end
end
