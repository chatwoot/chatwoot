module Api::V1::StringeePccHelper # rubocop:disable Metrics/ModuleLength
  def create_queue(name, route_type)
    response = create_queue_post(name, route_type)
    result = response.parsed_response
    return result['queueID'] if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.error("Queue created failure: #{result['message']}")
  end

  def delete_queue(queue_id)
    response = HTTParty.delete(
      URI.parse("https://icc-api.stringee.com/v1/queue/#{queue_id}"),
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token }
    )
    result = response.parsed_response
    return if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Queue deleted failure: #{result['message']}")
  end

  def add_group(group_name)
    response = add_group_post(group_name)
    result = response.parsed_response
    return result['groupID'] if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Group added failure: #{result['message']}")
  end

  def add_group_to_queue(queue_id, group_id)
    body =
      {
        queue_id: queue_id,
        group_id: group_id,
        primary_group: 1
      }
    response = HTTParty.post(
      URI.parse('https://icc-api.stringee.com/v1/routing-call-to-groups'),
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token },
      body: body.to_json
    )
    result = response.parsed_response
    return if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Add group to queue failure: #{result['message']}")
  end

  def add_agent_to_group(group_id, agent_id)
    body =
      {
        group_id: group_id,
        agent_id: agent_id
      }
    response = HTTParty.post(
      URI.parse('https://icc-api.stringee.com/v1/manage-agents-in-group'),
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token },
      body: body.to_json
    )
    result = response.parsed_response
    return if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Add agent to group failure: #{result['message']}")
  end

  def delete_agent_from_group(group_id, agent_id)
    body =
      {
        group_id: group_id,
        agent_id: agent_id
      }
    response = HTTParty.delete(
      URI.parse('https://icc-api.stringee.com/v1/manage-agents-in-group'),
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token },
      body: body.to_json
    )
    result = response.parsed_response
    return if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Delete agent to group failure: #{result['message']}")
  end

  def remove_group(group_id)
    response = HTTParty.delete(
      URI.parse("https://icc-api.stringee.com/v1/group/#{group_id}"),
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token }
    )
    result = response.parsed_response
    return if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Group removed failure: #{result['message']}")
  end

  def create_agent(name, user_id)
    response = create_agent_post(name, user_id)
    result = response.parsed_response
    return result['agentID'] if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Agent created failure: #{result['message']}")
  end

  def delete_agent(agent_id)
    response = HTTParty.delete(
      URI.parse("https://icc-api.stringee.com/v1/agent/#{agent_id}"),
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token }
    )
    result = response.parsed_response
    return if response.code == 200 && result['r'].to_i.zero?

    Rails.logger.warn("Agent deleted failure: #{result['message']}")
  end

  private

  def create_queue_post(name, route_type)
    body = { name: name }
    body[:get_list_agents_url] = "#{ENV.fetch('FRONTEND_URL')}/webhooks/stringee/agents" if route_type == 'from_list'
    body[:cond_routing] = 2 if route_type == 'by_group'

    HTTParty.post(
      'https://icc-api.stringee.com/v1/queue',
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token },
      body: body.to_json
    )
  end

  def add_group_post(group_name)
    HTTParty.post(
      'https://icc-api.stringee.com/v1/group',
      headers: { 'Content-Type' => 'application/json', 'X-STRINGEE-AUTH' => generate_access_token },
      body: { name: group_name }.to_json
    )
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
