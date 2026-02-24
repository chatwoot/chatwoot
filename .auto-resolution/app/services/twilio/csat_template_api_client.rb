class Twilio::CsatTemplateApiClient
  def initialize(twilio_channel)
    @twilio_channel = twilio_channel
  end

  def create_template(request_body)
    HTTParty.post(
      "#{api_base_path}/v1/Content",
      headers: api_headers,
      body: request_body.to_json
    )
  end

  def submit_for_approval(approval_url, template_name, category)
    request_body = {
      name: template_name,
      category: category
    }

    HTTParty.post(
      approval_url,
      headers: api_headers,
      body: request_body.to_json
    )
  end

  def delete_template(content_sid)
    HTTParty.delete(
      "#{api_base_path}/v1/Content/#{content_sid}",
      headers: api_headers
    )
  end

  def fetch_template(content_sid)
    HTTParty.get(
      "#{api_base_path}/v1/Content/#{content_sid}",
      headers: api_headers
    )
  end

  def fetch_approval_status(content_sid)
    HTTParty.get(
      "#{api_base_path}/v1/Content/#{content_sid}/ApprovalRequests",
      headers: api_headers
    )
  end

  private

  def api_headers
    {
      'Authorization' => "Basic #{encoded_credentials}",
      'Content-Type' => 'application/json'
    }
  end

  def encoded_credentials
    if @twilio_channel.api_key_sid.present?
      Base64.strict_encode64("#{@twilio_channel.api_key_sid}:#{@twilio_channel.auth_token}")
    else
      Base64.strict_encode64("#{@twilio_channel.account_sid}:#{@twilio_channel.auth_token}")
    end
  end

  def api_base_path
    'https://content.twilio.com'
  end
end
