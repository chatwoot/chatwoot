class ChatGpt
  def self.base_uri
    'https://api.openai.com'
  end

  def initialize(api_key)
    @api_key = api_key
    @model = 'gpt-4'
    system_message = { 'role': 'system',
                       'content': "You are a helpful support agent at Chatwoot.
                       If they ask to Chat with human agent return text 'conversation_handoff'." }
    @messages = [
      system_message
    ]
  end

  def generate_response(input, previous_messages = [])
    previous_messages.each do |message|
      @messages << message
    end

    @messages << { 'role': 'user', 'content': input } if input.present?
    headers = { 'Content-Type' => 'application/json',
                'Authorization' => "Bearer #{@api_key}" }
    body = {
      model: @model,
      messages: @messages
    }.to_json

    response = HTTParty.post("#{self.class.base_uri}/v1/chat/completions", headers: headers, body: body)
    response_body = JSON.parse(response.body)
    response_body['choices'][0]['message']['content'].strip
  end
end
