class WhatsappSubscriptionChecker
  pattr_initialize [:conversation!]

  def subscribed?
    Rails.logger.info("WhatsappSubscriptionChecker#subscribed? called for conversation_id: #{conversation.id}")

    unless whatsapp_channel?
      Rails.logger.info("Not a WhatsApp channel, allowing message - conversation_id: #{conversation.id}")
      return true
    end

    shop_url = fetch_shop_url
    if shop_url.blank?
      Rails.logger.info("Shop URL blank, allowing message - conversation_id: #{conversation.id}")
      return true
    end

    phone_number = fetch_phone_number
    if phone_number.blank?
      Rails.logger.info("Phone number blank, allowing message - conversation_id: #{conversation.id}")
      return true
    end

    Rails.logger.info("Checking subscription for shopUrl: #{shop_url}, phoneNumber: #{phone_number}")
    check_subscription_status(shop_url, phone_number)
  end

  private

  def whatsapp_channel?
    # Treat API inboxes with message templates as WhatsApp (mirrors frontend `isWhatsAppInbox` logic)
    conversation.inbox.channel.is_a?(Channel::Api) &&
      conversation.inbox.channel.additional_attributes.present? &&
      conversation.inbox.channel.additional_attributes['message_templates'].present?
  end

  def fetch_shop_url
    account_id = conversation.account_id
    response = HTTParty.get("https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/accountDetails/#{account_id}")
    return nil unless response.success?

    JSON.parse(response.body)['accountDetails']['shopUrl']
  rescue StandardError => e
    Rails.logger.error "Error fetching shop URL for subscription check: #{e.message}"
    nil
  end

  def fetch_phone_number
    conversation.contact.phone_number&.delete('+')
  end

  def check_subscription_status(shop_url, phone_number)
    response = HTTParty.get(
      'https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/whatsapp/subscription',
      query: {
        shopUrl: shop_url,
        phoneNumber: phone_number
      }
    )

    Rails.logger.info("WhatsappsubscriptioTest, #{response.inspect}")

    return true unless response.success?

    data = JSON.parse(response.body)
    subscription_status = data['subscription']

    Rails.logger.info("WhatsApp Subscription Status - shopUrl: #{shop_url}, phoneNumber: #{phone_number}, subscription: #{subscription_status}")

    # subscription == 1 means subscribed, subscription == 0 means unsubscribed
    subscription_status == 1
  rescue StandardError => e
    Rails.logger.error "Error checking subscription status: #{e.message}"
    # Default to true on error to avoid blocking legitimate messages
    true
  end
end
