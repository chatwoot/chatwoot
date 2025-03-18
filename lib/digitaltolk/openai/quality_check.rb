class Digitaltolk::Openai::QualityCheck < Digitaltolk::Openai::Base
  ANSWER_QUALITY_THRESHOLD = 95
  LANGUAGE_GRAMMAR_THRESHOLD = 90
  CUSTOMER_CENTRICITY_THRESHOLD = 90

  SYSTEM_PROMPT = %(
    You are an exceptional customer service quality analyst.
    Your task is to contextually evaluate the quality of a response to a query. You will be provided with:
    - The latest query from a client.
    - The response to evaluate

    Assess the response based on the following criteria and provide your output in a valid JSON format.

    Evaluation Criteria:
    1. Answer Quality Check
    - Assign a satisfaction score (0-100) based on accuracy, relevance, and completeness.
    Scoring Guidelines:
      - #{ANSWER_QUALITY_THRESHOLD} is the minimum acceptable score.
    - Provide a concise, actionable feedback explaining what's missing or how to enhance the response.
      - Determine the language of the query and response. Use the same language to provide feedback.
      - If the language is not detected, provide the feedback in English.
    - Provide a boolean indicating whether the response meets or exceeds the threshold.
    Format:
    "quality_check": {
      "score": <number>,
      "feedback": "<clear_and_concise_feedback>",
      "passed": <boolean>
    }

    2. Language & Grammar Check
    - Assign a professionalism score (0-100) based on spelling, grammar, clarity, and readability.
      - Use the language of the response to evaluate the grammar.
    - #{LANGUAGE_GRAMMAR_THRESHOLD} is the minimum acceptable score.
      - If the score is below 90, provide a corrected version of the response.
      - Consider the customer-centric tone of the corrected version.
    - Provide a boolean indicating whether the response meets or exceeds the threshold.
    Format:
    "language_grammar_check": {
      "score": <number>,
      "corrected_message": "<corrected_response>",
      "passed": <boolean>
    }

    3. Customer-Centricity Check
    - Assign a customer-centricity score (0-100) based on tone, empathy, and solution-oriented language.
      - #{CUSTOMER_CENTRICITY_THRESHOLD} is the minimum acceptable score.
    - Provide a boolean indicating whether the response meets or exceeds the threshold.
    Format:
    "customer_centricity_check": {
      "score": <number>,
      "passed": <boolean>
    }

    Important:
    Only return the combined JSON of response and passed keys.
    Response is the combined JSON of all the checks, enclosed by response key.
    Passed is a boolean indicating whether all checks passed.
    No additional text, explanations, or formatting outside of it.
  ).freeze

  USER_PROMPT = %(
    Here is the query and response you need to evaluate:
    Query: %s
    Response: %s
  ).freeze

  def perform(conversation, response)
    @conversation = conversation
    @response = response.to_s.strip
    return skip_check_response if should_skip_check?

    JSON.parse get_response_content(call_openai)
  rescue StandardError => e
    Rails.logger.error e
    skip_check_response.merge({ error: e.message })
  end

  private

  attr_reader :conversation, :response

  def get_response_content(response)
    response_object = if response.is_a?(Hash)
                        response
                      else
                        JSON.parse(response)
                      end

    response_object.with_indifferent_access.dig(:choices, 0, :message, :content) || '{}'
  end

  def incoming_messages
    conversation.messages.incoming
  end

  def prior_query
    incoming_messages.last
  end

  def question
    prior_query&.content
  end

  def system_prompt
    SYSTEM_PROMPT
  end

  def user_prompt
    format(USER_PROMPT, question, response)
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: user_prompt }
    ]
  end

  def skip_check_response
    { skipped: true }
  end

  def should_skip_check?
    return true if response.blank?
    return true if incoming_messages.blank?
    return true if question.blank?

    false
  end
end
