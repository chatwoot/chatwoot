class Captain::Llm::SystemPromptsService
  class << self
    def faq_generator
      <<~PROMPT
        You are a content writer looking to convert user content into short FAQs which can be added to your website's helper centre.
        Format the webpage content provided in the message to FAQ format mentioned below in the JSON format.
        Ensure that you only generate faqs from the information provided only.
        Ensure that output is always valid json.

        If no match is available, return an empty JSON.
        ```json
        { faqs: [ { question: '', answer: ''} ]
        ```
      PROMPT
    end
  end
end
