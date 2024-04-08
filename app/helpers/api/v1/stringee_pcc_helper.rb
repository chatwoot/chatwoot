module Api::V1::StringeePccHelper
  def create_queue(name)
    response = create_queue_post(name)
    result = response.parsed_response
    return result['queueID'] if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.error("Queue created result: #{result['message']}")
  end

  def delete_queue(queue_id)
    response = HTTParty.delete(
      URI.parse("https://icc-api.stringee.com/v1/queue/#{queue_id}"),
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token }
    )
    result = response.parsed_response
    return if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Queue deleted result: #{result['message']}")
  end

  def add_number(phone_number, nick_name, queue_id)
    response = add_number_post(phone_number, nick_name, queue_id)
    result = response.parsed_response
    return result['numberID'] if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Number added result: #{result['message']}")
  end

  def remove_number(number_id)
    response = HTTParty.delete(
      URI.parse("https://icc-api.stringee.com/v1/number/#{number_id}"),
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token }
    )
    result = response.parsed_response
    return if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Number removed result: #{result['message']}")
  end

  def create_agent(name, user_id)
    response = create_agent_post(name, user_id)
    result = response.parsed_response
    return result['agentID'] if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Agent created result: #{result['message']}")
  end

  def delete_agent(agent_id)
    response = HTTParty.delete(
      URI.parse("https://icc-api.stringee.com/v1/agent/#{agent_id}"),
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token }
    )
    result = response.parsed_response
    return if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Agent deleted result: #{result['message']}")
  end

  private

  def create_queue_post(name)
    HTTParty.post(
      'https://icc-api.stringee.com/v1/queue',
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token },
      body: { name: name, get_list_agents_url: "#{ENV.fetch('FRONTEND_URL')}/webhooks/stringee/agents" }.to_json
    )
  end

  def add_number_post(phone_number, nick_name, queue_id)
    HTTParty.post(
      'https://icc-api.stringee.com/v1/number',
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token },
      body: number_body(phone_number, nick_name, queue_id).to_json
    )
  end

  def number_body(phone_number, nick_name, queue_id)
    {
      number: phone_number,
      nickname: nick_name,
      allow_outbound_calls: true,
      enable_ivr: false,
      queue_id: queue_id,
      record_outbound_calls: true
    }
  end

  def create_agent_post(name, user_id)
    HTTParty.post(
      'https://icc-api.stringee.com/v1/agent',
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token },
      body: { name: name, stringee_user_id: user_id, manual_status: 'AVAILABLE' }.to_json
    )
  end

  def generate_access_token
    now = Time.now.to_i
    exp = now + (3 * 60)  # 3 minunutes
    api_key_sid = ENV.fetch('STRINGEE_API_KEY_SID', nil)
    api_key_secret = ENV.fetch('STRINGEE_API_KEY_SECRET', nil)

    header = { 'cty' => 'stringee-api;v=1' }
    payload = {
      'jti' => "#{api_key_sid}-#{now}",
      'iss' => api_key_sid,
      'exp' => exp,
      'rest_api' => true
    }

    JWT.encode(payload, api_key_secret, 'HS256', header)
  end
end
