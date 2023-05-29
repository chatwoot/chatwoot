class ChatGpt
  def self.base_uri
    'https://api.openai.com'
  end

  def initialize(api_key, context_sections = '')
    @api_key = api_key
    @model = 'gpt-4'
    system_message = { 'role': 'system',
                       'content': 'You are a very enthusiastic customer support representative who loves ' \
                                  'to help people! Given the following Context sections from the ' \
                                  'documentation, continue the conversation with only that information, ' \
                                  "outputed in markdown format along with context_ids in format 'response \n {context_ids: [values] }'  " \
                                  "\n If you are unsure and the answer is not explicitly written in the documentation,  " \
                                  "say 'Sorry, I don't know how to help with that. Do you want to chat with a human agent?' " \
                                  "If they ask to Chat with human agent return text 'conversation_handoff'." \
                                  "Context sections: \n" \
                                  "\n\n #{context_sections}}" }

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
