class Integrations::Openai::ProcessorService
  pattr_initialize [:hook!, :event!]

  def perform
    rephrase_message if event['name'] == 'rephrase'
  end

  private

  def rephrase_body(tone, message)
    {
      model: 'gpt-3.5-turbo',
      messages: [
        { role: 'system', content: "You are a helpful support agent. Please rephrase the following response to a more #{tone} tone." },
        { role: 'user', content: message }
      ]
    }.to_json
  end

  def rephrase_message
    response = make_api_call(rephrase_body(event['data']['tone'], event['data']['content']))
    JSON.parse(response)['choices'].first['message']['content']
  end

  def make_api_call(body)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{hook.settings['api_key']}"
    }

    response = HTTParty.post(
      'https://api.openai.com/v1/chat/completions',
      headers: headers,
      body: body
    )

    response.body
  end
end
