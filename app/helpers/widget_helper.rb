module WidgetHelper
  def build_contact_inbox_with_token(web_widget, additional_attributes = {})
    contact_inbox = web_widget.create_contact_inbox(additional_attributes)
    payload = { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id }
    token = ::Widget::TokenService.new(payload: payload).generate_token

    [contact_inbox, token]
  end

  def fetch_shop_url_from_api(account_id)
    # response = HTTParty.get('https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/accountDetails/1058')
    response = HTTParty.get("https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/accountDetails/#{account_id}")
    return nil unless response.success?

    JSON.parse(response.body)['accountDetails']['shopUrl']
  rescue StandardError => e
    Rails.logger.error "Error fetching shop URL: #{e.message}"
    nil
  end

  def fetch_whatsapp_redirect_url(shop_url, source_id, conversation_id)
    # response = HTTParty.get('https://container.bitespeed.co/api/v1/liveChat/getWhatsappUrl?shopUrl=bombay-shaving.myshopify.com&livechatUUID=ed7be67a-8605-42ca-bb67-42cbca75081a&conversationId')
    response = HTTParty.get("https://container.bitespeed.co/api/v1/liveChat/getWhatsappUrl?shopUrl=#{shop_url}&livechatUUID=#{source_id}&conversationId=#{conversation_id}")
    return nil if response['whatsappUrl'].blank?

    response
  rescue StandardError => e
    Rails.logger.error "Error fetching WhatsappRedirect_url: #{e.message}"
    nil
  end
end
