module Enterprise::Whatsapp::Providers::WhatsappCloudService
  def pre_accept_call(call_id, sdp_answer)
    call_api('pre_accept_call', call_action_body(call_id, 'pre_accept', sdp_answer))
  end

  def accept_call(call_id, sdp_answer)
    call_api('accept_call', call_action_body(call_id, 'accept', sdp_answer))
  end

  def reject_call(call_id)
    call_api('reject_call', call_action_body(call_id, 'reject'))
  end

  def terminate_call(call_id)
    call_api('terminate_call', call_action_body(call_id, 'terminate'))
  end

  def send_call_permission_request(to_phone_number, body_text = I18n.t('conversations.messages.whatsapp.call_permission_request_body'))
    response = HTTParty.post(
      "#{phone_id_path}/messages", headers: api_headers, body: permission_request_body(to_phone_number, body_text)
    )

    unless response.success?
      Rails.logger.error "[WHATSAPP CALL] send_call_permission_request failed: status=#{response.code} body=#{response.body}"
      return nil
    end

    response.parsed_response
  end

  def initiate_call(to_phone_number, sdp_offer)
    response = HTTParty.post(
      "#{phone_id_path}/calls", headers: api_headers, body: initiate_call_body(to_phone_number, sdp_offer)
    )
    process_initiate_call_response(response)
  end

  private

  def call_action_body(call_id, action, sdp_answer = nil)
    body = { messaging_product: 'whatsapp', call_id: call_id, action: action }
    body[:session] = { sdp: sdp_answer, sdp_type: 'answer' } if sdp_answer
    body
  end

  def call_api(action_name, body)
    url = "#{phone_id_path}/calls"
    Rails.logger.info "[WHATSAPP CALL] #{action_name} POST #{url} body=#{body.except(:session).to_json}"
    response = HTTParty.post(url, headers: api_headers, body: body.to_json)
    Rails.logger.error "[WHATSAPP CALL] #{action_name} failed: status=#{response.code} body=#{response.body}" unless response.success?
    response.success?
  end

  def permission_request_body(to_phone_number, body_text)
    {
      messaging_product: 'whatsapp', recipient_type: 'individual', to: to_phone_number,
      type: 'interactive',
      interactive: {
        type: 'call_permission_request',
        action: { name: 'call_permission_request' },
        body: { text: body_text }
      }
    }.to_json
  end

  def initiate_call_body(to_phone_number, sdp_offer)
    {
      messaging_product: 'whatsapp', to: to_phone_number, type: 'audio',
      session: { sdp: sdp_offer, sdp_type: 'offer' }
    }.to_json
  end

  def process_initiate_call_response(response)
    return response.parsed_response if response.success?

    Rails.logger.error "[WHATSAPP CALL] initiate_call failed: status=#{response.code} body=#{response.body}"
    parsed = response.parsed_response.is_a?(Hash) ? response.parsed_response : {}
    error_code = parsed.dig('error', 'code')
    error_msg = parsed.dig('error', 'error_user_msg') || 'Failed to initiate call'

    raise Voice::CallErrors::NoCallPermission, error_msg if error_code == Voice::CallErrors::NO_CALL_PERMISSION_CODE

    raise Voice::CallErrors::CallFailed, error_msg
  end
end
