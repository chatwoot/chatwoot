require 'cgi'

class Whatsapp::Providers::UnoapiService < Whatsapp::Providers::WhatsappCloudService
  def validate_provider_config?
    url = "#{business_account_path}/message_templates?access_token=#{ENV.fetch('UNOAPI_AUTH_TOKEN', whatsapp_channel.provider_config['api_key'])}"
    return Whatsapp::UnoapiWebhookSetupService.new.perform(whatsapp_channel) if HTTParty.get(url).success?
  end

  def group_participants(group_id)
    HTTParty.get("#{unoapi_group_path(group_id)}/participants", headers: api_headers)
  end

  def send_message_edit(phone_number, message, content)
    request_body = {
      messaging_product: 'whatsapp',
      recipient_type: recipient_type_for(message),
      to: phone_number,
      type: 'message_edit',
      context: { message_id: message.source_id },
      text: { body: content.to_s }
    }

    response = HTTParty.post(messages_path, headers: api_headers, body: request_body.to_json)
    return response.parsed_response.dig('messages', 0, 'id') if response.success? && response.parsed_response['error'].blank?

    Rails.logger.error(response.body)
    nil
  end

  def create_group(subject:, participants:, description: nil, join_approval_mode: nil)
    payload = {
      subject: subject,
      description: description,
      participants: participants,
      join_approval_mode: join_approval_mode
    }.compact

    HTTParty.post("#{unoapi_phone_path}/groups", headers: api_headers, body: payload.to_json)
  end

  def group_details(group_id)
    HTTParty.get(unoapi_group_path(group_id), headers: api_headers)
  end

  def update_group(group_id:, subject: nil, description: nil, picture_url: nil)
    payload = {
      subject: subject,
      description: description,
      picture: picture_url.present? ? { url: picture_url } : nil
    }.compact

    HTTParty.patch(unoapi_group_path(group_id), headers: api_headers, body: payload.to_json)
  end

  def group_invite_link(group_id)
    HTTParty.get("#{unoapi_group_path(group_id)}/invite_link", headers: api_headers)
  end

  def reset_group_invite_link(group_id)
    HTTParty.post("#{unoapi_group_path(group_id)}/invite_link", headers: api_headers)
  end

  def add_group_participants(group_id:, participants:)
    HTTParty.post(
      "#{unoapi_group_path(group_id)}/participants",
      headers: api_headers,
      body: { participants: participants }.to_json
    )
  end

  def remove_group_participants(group_id:, participants:)
    HTTParty.delete(
      "#{unoapi_group_path(group_id)}/participants",
      headers: api_headers,
      body: { participants: participants }.to_json
    )
  end

  def group_join_requests(group_id)
    HTTParty.get("#{unoapi_group_path(group_id)}/join_requests", headers: api_headers)
  end

  def approve_group_join_requests(group_id:, participants:)
    HTTParty.post(
      "#{unoapi_group_path(group_id)}/join_requests",
      headers: api_headers,
      body: { participants: participants }.to_json
    )
  end

  def reject_group_join_requests(group_id:, participants:)
    HTTParty.delete(
      "#{unoapi_group_path(group_id)}/join_requests",
      headers: api_headers,
      body: { participants: participants }.to_json
    )
  end

  private

  def unoapi_group_path(group_id)
    "#{unoapi_phone_path}/groups/#{CGI.escape(group_id.to_s)}"
  end

  def unoapi_phone_path
    uno_session_id = whatsapp_channel.provider_config['phone_number_id'].presence || whatsapp_channel.provider_config['business_account_id']
    "#{api_base_path}/v15.0/#{uno_session_id}"
  end
end
