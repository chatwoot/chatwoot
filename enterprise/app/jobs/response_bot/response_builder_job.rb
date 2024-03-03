class ResponseBot::ResponseBuilderJob < ApplicationJob
  queue_as :default

  def perform(response_document)
    reset_previous_responses(response_document)
    data = prepare_data(response_document)
    response = post_request(data)
    create_responses(response, response_document)
  end

  private

  def reset_previous_responses(response_document)
    response_document.responses.destroy_all
  end

  def prepare_data(response_document)
    {
      model: 'gpt-3.5-turbo',
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: system_message_content
        },
        {
          role: 'user',
          content: response_document.content
        }
      ]
    }
  end

  def system_message_content
    <<~SYSTEM_MESSAGE_CONTENT
      You are a content writer looking to convert user content into short FAQs which can be added to your website's helper centre.
      Format the webpage content provided in the message to FAQ format mentioned below in the json
      Ensure that you only generate faqs from the information provider in the message.
      Ensure that output is always valid json.
      If no match is available, return an empty JSON.

      ```json
      {faqs: [{question: '', answer: ''}]
      ```
    SYSTEM_MESSAGE_CONTENT
  end

  def post_request(data)
    headers = prepare_headers
    HTTParty.post(
      'https://api.openai.com/v1/chat/completions',
      headers: headers,
      body: data.to_json
    )
  end

  def prepare_headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
    }
  end

  def create_responses(response, response_document)
    response_body = JSON.parse(response.body)
    content = response_body.dig('choices', 0, 'message', 'content')

    return if content.nil?

    faqs = JSON.parse(content.strip).fetch('faqs', [])

    faqs.each do |faq|
      response_document.responses.create!(
        question: faq['question'],
        answer: faq['answer'],
        response_source: response_document.response_source
      )
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response document : #{e.message}"
  end
end
