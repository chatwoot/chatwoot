class LandingPage::RequestLandingPageService
  def initialize(inbox)
    @inbox = inbox
    @channel = inbox.channel
  end

  def perform
    validate_channel!
    response = request_landing_page_url
    update_landing_page_url(response)
  rescue StandardError => e
    Rails.logger.error "[REQUEST_LANDING_PAGE] Error requesting landing page: #{e.message}"
    raise e
  end

  private

  def validate_channel!
    raise ArgumentError, 'Inbox is required' if @inbox.blank?
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'Channel must be a WebWidget' unless @channel.is_a?(Channel::WebWidget)
    raise ArgumentError, 'Landing page endpoint URL is not configured' if landing_page_endpoint.blank?
  end

  def request_landing_page_url
    response = HTTParty.post(
      landing_page_endpoint,
      body: request_payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 60
    )

    handle_response(response)
  end

  def request_payload
    {
      inbox_name: @inbox.name,
      website_url: @channel.website_url,
      website_token: @channel.website_token,
      landing_page_description: @channel.landing_page_description,
      frontend_url: ENV.fetch('FRONTEND_URL', '')
    }
  end

  def handle_response(response)
    unless response.success?
      error_message = "Landing page API request failed: #{response.code} - #{response.body}"
      Rails.logger.error "[REQUEST_LANDING_PAGE] #{error_message}"
      raise error_message
    end

    parsed_response = response.parsed_response
    landing_page_url = parsed_response['url']

    raise 'Landing page URL not found in response' if landing_page_url.blank?

    landing_page_url
  end

  def update_landing_page_url(url)
    @channel.update!(landing_page_url: url)
    Rails.logger.info "[REQUEST_LANDING_PAGE] Successfully updated landing page URL for inbox #{@inbox.id}"
  end

  def landing_page_endpoint
    ENV.fetch('LANDING_PAGE_GENERATION_ENDPOINT', nil)
  end
end
