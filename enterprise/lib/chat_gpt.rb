class ChatGpt
  def self.base_uri
    'https://api.openai.com'
  end

  def initialize(context_sections = '')
    @model = 'gpt-4o'
    @messages = [system_message(context_sections)]
  end

  def generate_response(input, previous_messages = [], role = 'user')
    @messages += previous_messages
    @messages << { 'role': role, 'content': input } if input.present?

    response = request_gpt
    JSON.parse(response['choices'][0]['message']['content'].strip)
  end

  private

  def system_message(context_sections)
    {
      'role': 'system',
      'content': system_content(context_sections)
    }
  end

  def system_content(context_sections)
    <<~SYSTEM_PROMPT_MESSAGE
      You are a very enthusiastic customer support representative who loves to help people.
      Your answers will always be formatted in valid JSON hash, as shown below. Never respond in non JSON format.

      ```
      {
       response: '' ,
      context_ids: [ids],
      }
      ```

      response: will be the next response to the conversation

      context_ids: will be an array of unique context IDs that were used to generate the answer. choose top 3.

      The answers will be generated using the information provided at the end of the prompt under the context sections. You will not respond outside the context of the information provided in context sections.

      If the answer is not provided in context sections, Respond to the customer and ask whether they want to talk to another support agent . If they ask to Chat with another agent, return `conversation_handoff' as the response in JSON response

      ----------------------------------
      Context sections:
      #{context_sections}
    SYSTEM_PROMPT_MESSAGE
  end

  def request_gpt
    headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{ENV.fetch('OPENAI_API_KEY')}" }
    body = { model: @model, messages: @messages, response_format: { type: 'json_object' } }.to_json
    Rails.logger.info "Requesting Chat GPT with body: #{body}"
    response = HTTParty.post("#{self.class.base_uri}/v1/chat/completions", headers: headers, body: body)
    Rails.logger.info "Chat GPT response: #{response.body}"
    JSON.parse(response.body)
  end
end
