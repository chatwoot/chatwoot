require 'httparty'

class Captain::Llm::AssistantChatService
  include HTTParty
  base_uri ENV.fetch('FLOWISE_API_URL', 'https://ai.radyalabs.id/api/v1')

  def initialize(question, session_id, chat_flow_id)
    @question = question
    @session_id = session_id
    @chat_flow_id = chat_flow_id
  end

  def generate_response
    self.class.post(
      "/prediction/#{@chat_flow_id}",
      body: {
        'question' => @question,
        'overrideConfig' => {
          'sessionId' => @session_id
        }
      }.to_json,
      headers: headers
    )
  end

  private

  def headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'Authorization' => "Bearer #{ENV.fetch('FLOWISE_API_KEY', nil)}"
    }
  end
end
