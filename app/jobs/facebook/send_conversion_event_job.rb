class Facebook::SendConversionEventJob < ApplicationJob
  queue_as :low
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(facebook_tracking_id)
    facebook_tracking = FacebookAdsTracking.find(facebook_tracking_id)
    return if facebook_tracking.conversion_sent?

    # Kiểm tra cấu hình Facebook Dataset
    dataset_config = get_dataset_config(facebook_tracking.inbox)
    return unless dataset_config&.dig('enabled')

    begin
      response = send_conversion_event(facebook_tracking, dataset_config)
      
      if response['error'].present?
        Rails.logger.error("Facebook Conversion API error: #{response['error']}")
        raise StandardError, "Facebook Conversion API error: #{response['error']['message']}"
      else
        facebook_tracking.mark_conversion_sent!(response)
        Rails.logger.info("Successfully sent Facebook conversion event for tracking #{facebook_tracking.id}")
      end

    rescue StandardError => e
      Rails.logger.error("Failed to send Facebook conversion event for tracking #{facebook_tracking.id}: #{e.message}")
      raise e
    end
  end

  private

  def get_dataset_config(inbox)
    # Lấy cấu hình từ inbox hoặc account
    inbox.channel.provider_config&.dig('facebook_dataset') ||
      inbox.account.settings&.dig('facebook_dataset')
  end

  def send_conversion_event(facebook_tracking, config)
    pixel_id = config['pixel_id']
    access_token = config['access_token']
    test_event_code = config['test_event_code'] # For testing

    url = "https://graph.facebook.com/v18.0/#{pixel_id}/events"
    
    payload = {
      data: [facebook_tracking.conversion_event_data],
      access_token: access_token
    }

    # Thêm test event code nếu đang test
    payload[:test_event_code] = test_event_code if test_event_code.present?

    Rails.logger.info("Sending Facebook conversion event: #{payload.to_json}")

    response = HTTParty.post(
      url,
      body: payload.to_json,
      headers: {
        'Content-Type' => 'application/json'
      },
      timeout: 30
    )

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse Facebook Conversion API response: #{e.message}")
    { 'error' => { 'message' => 'Invalid response format' } }
  rescue HTTParty::Error, Net::TimeoutError => e
    Rails.logger.error("HTTP error sending Facebook conversion event: #{e.message}")
    { 'error' => { 'message' => e.message } }
  end
end
