class Digitaltolk::Openai::QualityCheck < Digitaltolk::Openai::Base
  ANSWER_QUALITY_THRESHOLD = 90
  LANGUAGE_GRAMMAR_THRESHOLD = 90
  CUSTOMER_CENTRICITY_THRESHOLD = 90

  SYSTEM_PROMPT = %(
    You are an exceptional customer service quality analyst.
    Your task is to contextually evaluate the quality of an answer to a query.
    Evaluate the answer based solely on its content and reasoning, regardless of the language used.
    You will be provided with.
    - The latest query from a client.
    - The answer to evaluate

    Assess the answer based on the following criteria and provide your output in a valid JSON format.

    Evaluation Criteria:
    1. Answer Quality Check

    - Assign a satisfaction score (0-100) based on accuracy and completeness.
      - #{ANSWER_QUALITY_THRESHOLD} is the minimum acceptable score.
      - Do not assess language alignment when evaluating relevance of the answer.
      - Focus only on content accuracy and thought, regardless of whether the response matches the query's language.
      - Allow for some flexibility in the answer's language.
    - Provide a concise, actionable feedback explaining what's missing or how to enhance the answer.
      - Use the language of the answer to provide feedback.
    - Provide a boolean indicating whether the satisfaction score meets or exceeds the threshold.

    2. Language & Grammar Check
    - Assign a professionalism score (0-100) based on spelling, grammar, clarity, and readability.
      - Use the language of the answer to evaluate the grammar.
      - If the score is below 90, provide a corrected version of the answer.
      - Consider the customer-centric tone of the corrected version.
      - #{LANGUAGE_GRAMMAR_THRESHOLD} is the minimum acceptable score.
    - Provide a boolean indicating whether the professionalism score  meets or exceeds the threshold.

    3. Customer-Centricity Check
    - Assign a customer-centricity score (0-100)
      - Evaluate if the message is structured with a customer-first approach (e.g., friendly, empathetic, solution-oriented).
      - #{CUSTOMER_CENTRICITY_THRESHOLD} is the minimum acceptable score.
    - Provide a boolean indicating whether the customer-centricity score meets or exceeds the threshold.

    Format:
    {
      "checks": {
        "quality_check": {
          "score": <number>,
          "feedback": "<clear_and_concise_feedback>",
          "passed": <boolean>
        },
        "language_grammar_check": {
          "score": <number>,
          "corrected_message": "<optional_corrected_answer>",
          "passed": <boolean>,
        },
        "customer_centricity_check": {
          "score": <number>,
          "passed": <boolean>
        }
      },
      "passed": <boolean>,
      "detected_language": "<language_of_the_answer>"
      "using_target_language": "<boolean>"
    }

    Important:
    checks are the combined JSON of all the checks, enclosed by checks key.
    passed is a boolean indicating whether all checks passed.
    detected_language is the language of the answer.
    using_target_language is a boolean indicating whether the detected_language of the answer is in the target language which is %<target_language>s.
    Only return the JSON format.
    No additional text, explanations, or formatting outside of it.
  ).freeze

  USER_PROMPT = %(
    Here is the query and answer you need to evaluate:
    Query: %s
    Answer: %s
  ).freeze

  def perform(conversation, response, target_language = 'Swedish')
    @conversation = conversation
    @response = response.to_s.strip
    @target_language = target_language
    return skip_check_response if should_skip_check?

    JSON.parse get_response_content(call_openai)
  rescue StandardError => e
    Rails.logger.error e
    skip_check_response.merge({ error: e.message })
  end

  private

  attr_reader :conversation, :response

  def get_response_content(response)
    response_object = parse_response(response)
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
    format(SYSTEM_PROMPT, target_language: @target_language)
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
