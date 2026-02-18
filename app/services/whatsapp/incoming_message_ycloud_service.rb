# YCloud webhook payload format:
# https://docs.ycloud.com/reference/whatsapp-inbound-message-webhook-examples
#
# Inbound messages arrive as:
# {
#   "id": "evt_xxx",
#   "type": "whatsapp.inbound_message.received",
#   "whatsappInboundMessage": {
#     "id": "msg_id", "wamid": "wamid.xxx",
#     "from": "customer_phone", "to": "business_phone",
#     "customerProfile": { "name": "Customer Name" },
#     "type": "text", "text": { "body": "..." }, ...
#   }
# }
#
# Status updates arrive as:
# {
#   "id": "evt_xxx",
#   "type": "whatsapp.message.updated",
#   "whatsappMessage": { "id": "msg_id", "wamid": "wamid.xxx", "status": "delivered", ... }
# }
class Whatsapp::IncomingMessageYcloudService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= transform_ycloud_params
  end

  def transform_ycloud_params
    event_type = params[:type]

    if event_type == 'whatsapp.inbound_message.received'
      transform_inbound_message
    elsif event_type == 'whatsapp.message.updated'
      transform_status_update
    end
  end

  def transform_inbound_message
    inbound = params[:whatsappInboundMessage]
    return {} if inbound.blank?

    {
      contacts: [{
        profile: { name: inbound.dig(:customerProfile, :name) || inbound[:from] },
        wa_id: inbound[:from]
      }],
      messages: [build_message_from_inbound(inbound)]
    }
  end

  def build_message_from_inbound(inbound)
    message = {
      id: inbound[:wamid] || inbound[:id],
      from: inbound[:from],
      type: inbound[:type],
      timestamp: Time.zone.now.to_i.to_s
    }

    # Copy the type-specific payload (text, image, audio, video, document, location, contacts, button, interactive)
    type_key = inbound[:type]&.to_sym
    message[type_key] = inbound[type_key] if type_key && inbound[type_key].present?

    # Copy context for reply threading
    message['context'] = inbound[:context] if inbound[:context].present?

    message
  end

  def transform_status_update
    wa_message = params[:whatsappMessage]
    return {} if wa_message.blank?

    {
      statuses: [{
        id: wa_message[:wamid] || wa_message[:id],
        status: wa_message[:status],
        errors: wa_message[:whatsappApiError].present? ? [{ code: wa_message[:errorCode], title: wa_message[:errorMessage] }] : nil
      }.compact]
    }
  end

  def download_attachment_file(attachment_payload)
    url = attachment_payload[:link] || inbox.channel.media_url(attachment_payload[:id])
    response = HTTParty.head(url, headers: inbox.channel.api_headers)
    inbox.channel.authorization_error! if response.unauthorized? || response.forbidden?
    return unless response.success?

    Down.download(url, headers: inbox.channel.api_headers)
  end
end
