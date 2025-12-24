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
    response = HTTParty.get("https://restapis.bitespeed.co/api/v1/liveChat/getWhatsappUrl?shopUrl=#{shop_url}&livechatUUID=#{source_id}&conversationId=#{conversation_id}")
    return nil if response['whatsappUrl'].blank?

    response
  rescue StandardError => e
    Rails.logger.error "Error fetching WhatsappRedirect_url: #{e.message}"
    nil
  end

  def fetch_whatsapp_widget_url(shop_url, default_text, phone_number)
    # Build base URL
    url = "https://restapis.bitespeed.co/api/v1/liveChat/getWhatsappUrlForWidget?shopUrl=#{shop_url}&defaultText=#{default_text}"

    # Add phone number only if it's present and not empty
    url += "&phoneNumber=#{phone_number.delete('+')}" if phone_number.present?

    response = HTTParty.get(url)
    return nil if response['whatsappUrl'].blank?

    response
  rescue StandardError => e
    Rails.logger.error "Error fetching WhatsappRedirect_url: #{e.message}"
    nil
  end

  def fetch_live_chat_bot_config(shop_url)
    response = HTTParty.get(
      'https://restapis.bitespeed.co/api/v1/liveChat/liveChatBotConfig',
      query: { shopUrl: shop_url }
    )
    return nil unless response.success?

    JSON.parse(response.body)['liveChatBotConfig']['config']
  rescue StandardError => e
    Rails.logger.error "Error fetching live chat bot config hours: #{e.message}"
    nil
  end

  def update_popup_id_in_bot_config(shop_url, popup_id)
    response = HTTParty.patch(
      'https://restapis.bitespeed.co/api/v1/liveChat/liveChatPopupId',
      body: {
        shopUrl: shop_url,
        popupId: popup_id
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    return nil unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error "Error fetching working hours: #{e.message}"
    nil
  end

  def fetch_checkout_url(shop_url, source_id, line_items)
    # response = HTTParty.get("https://glorious-heavily-platypus.ngrok-free.app/api/v1/liveChat/getCheckoutUrl?shopUrl=#{shop_url}&livechatUUID=#{source_id}&lineItems=#{encoded_line_items}")
    encoded_line_items = URI.encode_www_form_component(line_items.to_json)
    response = HTTParty.get("https://restapis.bitespeed.co/api/v1/liveChat/getCheckoutUrl?shopUrl=#{shop_url}&livechatUUID=#{source_id}&lineItems=#{encoded_line_items}")

    return nil if response['checkoutUrl'].blank?

    response
  rescue StandardError => e
    Rails.logger.error "Error fetching CheckoutURL: #{e.message}"
    nil
  end

  def fetch_main_menu_message(shop_url, source_id)
    response = HTTParty.post(
      'https://restapis.bitespeed.co/api/v1/liveChat/sendMainMenuMessage',
      body: {
        shopUrl: shop_url,
        livechatUUID: source_id
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    return nil unless response.success?

    JSON.parse(response.body)
  rescue StandardError => e
    Rails.logger.error "Error sending main menu message: #{e.message}"
    nil
  end
end
