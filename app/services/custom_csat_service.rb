class CustomCsatService
  pattr_initialize [:conversation!]

  SHOP_URL_TTL = 24.hours

  def perform  # rubocop:disable Metrics/MethodLength  , Metrics/AbcSize
    # Check if user is subscribed before sending CSAT message
    unless WhatsappSubscriptionChecker.new(conversation: conversation).subscribed?
      Rails.logger.info("CSAT message not sent - user unsubscribed: conversation_id=#{conversation.id}")
      return false
    end

    shop_url = fetch_shop_url_from_api(conversation.account_id)
    return false if shop_url.blank?

    Rails.logger.info("shop_url_Data, #{shop_url}")

    Rails.logger.info("ConversationData, #{conversation.inspect}")

    user_phone_number = conversation.contact.phone_number.delete('+')

    response = HTTParty.post(
      'https://restapis.bitespeed.co/api/v1/chatbot/wa/sendCsatMessage',
      body: {
        phoneNumber: user_phone_number,
        shopUrl: shop_url,
        chatUUID: conversation.uuid
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    Rails.logger.info("response From Custom CSAT, #{response}")

    # Update conversation with CSAT sending time
    if response.success?
      conversation.additional_attributes ||= {}
      conversation.additional_attributes['csat_sent_at'] = Time.current
      conversation.save!
      Rails.logger.info("CSAT sent successfully and timestamp recorded: conversation_id=#{conversation.id}")
    else
      Rails.logger.error("Failed to send CSAT message: conversation_id=#{conversation.id}, response=#{response.code}")
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching shop URL: #{e.message}"
  end

  private

  def fetch_shop_url_from_api(account_id)
    # response = HTTParty.get('https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/accountDetails/1058')
    response = HTTParty.get("https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/accountDetails/#{account_id}")
    return nil unless response.success?

    Rails.logger.info("responseDataFrom ShopUrl, #{response.inspect}")

    JSON.parse(response.body)['accountDetails']['shopUrl']
  rescue StandardError => e
    Rails.logger.error "Error fetching shop URL: #{e.message}"
    nil
  end
end
