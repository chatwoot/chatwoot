require 'httparty'

class Captain::Llm::BaseJangkauService
  include HTTParty
  base_uri ENV.fetch('JANGKAU_AGENT_API_URL', 'https://agent.jangkau.ai/')

  # default_options.update(
  #   open_timeout: ENV.fetch('JANGKAU_AGENT_API_OPEN_TIMEOUT', 5).to_i,
  #   read_timeout: ENV.fetch('JANGKAU_AGENT_API_READ_TIMEOUT', 15).to_i,
  #   write_timeout: ENV.fetch('JANGKAU_AGENT_API_WRITE_TIMEOUT', 30).to_i
  # )

  def initialize(account_id, ai_agent, question, session_id, additional_attributes)
    @account_id = account_id
    @ai_agent = ai_agent
    @question = question
    @session_id = session_id
    @additional_attributes = additional_attributes
  end

  def perform
    generate_response
  end

  private

  def generate_response # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    Rails.logger.info '[generate_response] Generating response for Jangkau AI Agent'

    # 👇 Build the full URL
    base_url = self.class.base_uri.strip # e.g., "https://agent.jangkau.ai/v2"
    endpoint = '/v2/chat/override/' # the path you're POSTing to
    full_url = "#{base_url}#{endpoint}" # 👈 Full URL

    Rails.logger.info "[generate_response] Request will be sent to: #{full_url}"
    Rails.logger.info "[generate_response] Request message: #{@question}"

    response = self.class.post(
      '/v2/chat/override/',
      body: request_body.to_json,
      headers: headers
    )
    Rails.logger.info "[generate_response] Received Jangkau response: #{response.code} #{response.body}"
    response
  rescue Net::OpenTimeout => e
    Rails.logger.error "[generate_response] Net::OpenTimeout error: #{e.message}"
    raise "Failed to generate response: #{e.message}"
  rescue Net::ReadTimeout => e
    Rails.logger.error "[generate_response] Net::ReadTimeout error: #{e.message}"
    raise "Failed to generate response: #{e.message}"
  rescue Net::WriteTimeout => e
    Rails.logger.error "[generate_response] Net::WriteTimeout error: #{e.message}"
  rescue HTTParty::Error => e
    Rails.logger.error "[generate_response] HTTParty error: #{e.message}"
    raise "Failed to generate response: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "[generate_response] Standard error: #{e.message}"
    raise "Failed to generate response: #{e.message}"
  end

  def request_body
    {
      'question' => @question,
      'overrideConfig' => {
        'sessionId' => @session_id.to_s,
        'vars' => {
          'account_id' => @account_id.to_s,
          'customer_name' => @additional_attributes['name'] || '',
          'contact' => @additional_attributes['phone_number'] || '',
          'channel' => @additional_attributes['channel'] || ''
        }.merge(@ai_agent.flow_data || {})
      }
    }
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
      # 'Authorization' => "Bearer #{ENV.fetch('JANGKAU_AGENT_API_KEY', nil)}"
    }
  end
end
