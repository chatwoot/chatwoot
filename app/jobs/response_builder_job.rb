class ResponseBuilderJob < ApplicationJob
  queue_as :default

  def perform(response_document_id)
    response_document = ResponseDocument.find(response_document_id)
    # resetting previous responses
    response_document.responses.destroy_all

    gpt_settings = openai_settings(response_document.account)
    return if gpt_settings['api_key'].blank?

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{gpt_settings['api_key']}"
    }

    data = {
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: " You are a content writer looking to convert user content into short FAQs which can be added to your website's helper centre.\n    \n    Format the webpage content provided in the message to fAQ format like the following example. Ensure that you only generate faqs from the information provider in the message. Ensure that output is always valid json.  If no match is available, return an empty JSON.\n    \n    ```\n   [ { \"question\": \"What is the pricing?\",\n      \"answer\" : \" There are different pricing tiers available.\"\n    }]\n    \n    ````"
        },
        {
          role: 'user',
          content: response_document.content
        }
      ]
    }

    response = HTTParty.post(
      'https://api.openai.com/v1/chat/completions',
      headers: headers,
      body: data.to_json
    )

    response_body = JSON.parse(response.body)
    faqs = JSON.parse(response_body['choices'][0]['message']['content'].strip)

    faqs.each do |faq|
      response_document.responses.create!(question: faq['question'], answer: faq['answer'], account_id: response_document.account_id)
    end
  end

  def openai_settings(account)
    account.hooks.find { |app| app.app_id == 'openai' }&.settings || {}
  end
end
