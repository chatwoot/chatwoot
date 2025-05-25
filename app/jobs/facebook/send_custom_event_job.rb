class Facebook::SendCustomEventJob < ApplicationJob
  queue_as :low
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(facebook_tracking_id, custom_event_data)
    facebook_tracking = FacebookAdsTracking.find(facebook_tracking_id)

    # Kiểm tra cấu hình Facebook Dataset
    dataset_config = get_dataset_config(facebook_tracking.inbox)
    return unless dataset_config&.dig('enabled')

    begin
      response = send_custom_event(custom_event_data, dataset_config)
      
      if response['error'].present?
        Rails.logger.error("Facebook Custom Event API error: #{response['error']}")
        raise StandardError, "Facebook Custom Event API error: #{response['error']['message']}"
      else
        Rails.logger.info("Successfully sent Facebook custom event for tracking #{facebook_tracking.id}: #{custom_event_data[:event_name]}")
        
        # Log custom event
        facebook_tracking.update!(
          additional_attributes: (facebook_tracking.additional_attributes || {}).merge(
            custom_events: ((facebook_tracking.additional_attributes || {})['custom_events'] || []) + [
              {
                event_name: custom_event_data[:event_name],
                event_value: custom_event_data.dig(:custom_data, :value),
                sent_at: Time.current,
                response: response
              }
            ]
          )
        )
      end

    rescue StandardError => e
      Rails.logger.error("Failed to send Facebook custom event for tracking #{facebook_tracking.id}: #{e.message}")
      raise e
    end
  end

  private

  def get_dataset_config(inbox)
    # Lấy cấu hình từ inbox hoặc account
    inbox.channel.provider_config&.dig('facebook_dataset') ||
      inbox.account.settings&.dig('facebook_dataset')
  end

  def send_custom_event(event_data, config)
    pixel_id = config['pixel_id']
    access_token = config['access_token']
    test_event_code = config['test_event_code'] # For testing

    url = "https://graph.facebook.com/v18.0/#{pixel_id}/events"
    
    payload = {
      data: [event_data],
      access_token: access_token
    }

    # Thêm test event code nếu đang test
    payload[:test_event_code] = test_event_code if test_event_code.present?

    Rails.logger.info("Sending Facebook custom event: #{payload.to_json}")

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
    Rails.logger.error("Failed to parse Facebook Custom Event API response: #{e.message}")
    { 'error' => { 'message' => 'Invalid response format' } }
  rescue HTTParty::Error, Net::TimeoutError => e
    Rails.logger.error("HTTP error sending Facebook custom event: #{e.message}")
    { 'error' => { 'message' => e.message } }
  end
end
