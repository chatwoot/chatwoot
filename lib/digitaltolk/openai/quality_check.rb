class Digitaltolk::Openai::QualityCheck < Digitaltolk::Openai::Base
  ANSWER_QUALITY_THRESHOLD = 90
  LANGUAGE_GRAMMAR_THRESHOLD = 90
  CUSTOMER_CENTRICITY_THRESHOLD = 90

  SYSTEM_PROMPT = %(
    You are an exceptional customer service quality analyst and translation agent.
    Your task is to contextually evaluate the quality of an answer to a query.
    Evaluate the answer based solely on its content and reasoning, regardless of the language used.
    You will be provided with.
    - The latest query from a customer.
    - The answer to evaluate

    Assess the <answer> based on the following criteria and provide your output in a valid JSON format.

    Evaluation Criteria:
    1. Answer Quality Check
    - Assign a satisfaction score (0-100) based on accuracy and completeness.
      - #{ANSWER_QUALITY_THRESHOLD} is the minimum acceptable score.
      - Do not assess language alignment when evaluating relevance of the <answer>.
      - Focus only on content accuracy and thought, regardless of whether the <answer> matches the <query>'s language.
      - Allow for some flexibility in the <answer>'s language.
    - Analyze the given <answer> and provide concise, actionable feedback on how to improve it. Identify any missing details, unclear explanations, or areas for enhancement. Detect the language of the <answer> and provide feedback in the same language.
    - Provide a boolean indicating whether the satisfaction score meets or exceeds the threshold.

    2. Language & Grammar Check
    - Assign a professionalism score (0-100) based on spelling, grammar, clarity, and readability.
      - Use the language of the <answer> to evaluate the grammar.
      - If the score is below 90, provide a corrected version of the <answer>.
      - Consider the customer-centric tone of the corrected version.
      - #{LANGUAGE_GRAMMAR_THRESHOLD} is the minimum acceptable score.
    - Provide a boolean indicating whether the professionalism score  meets or exceeds the threshold.

    3. Customer-Centricity Check
    - Assign a customer-centricity score (0-100)
      - Evaluate if the <answer> is structured with a customer-first approach (e.g., friendly, empathetic, solution-oriented).
      - #{CUSTOMER_CENTRICITY_THRESHOLD} is the minimum acceptable score.
    - Provide a boolean indicating whether the customer-centricity score meets or exceeds the threshold.

    - Perform needs_translation check
      - compare <query> and <answer> and determine if <answer> needs to be translated
      - on uncertainity, return true
      - store the boolean value in <needs_translation> field

    Declare the following internal variables:
    - checks: are the combined JSON of all the checks, enclosed by checks key.
    - passed: is a boolean indicating whether all checks passed.

    Format:
    {
      "checks": {
        "quality_check": {
          "score": <number>,
          "feedback": "<feedback_on_detected_answer_language>",
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
      "passed": <passed>,
      "needs_translation": <needs_translation>
    }

    Important:
    The JSON format should be valid and parsable.
    Only return the JSON format.
    No additional text, explanations, white spaces or formatting outside of it.
  ).freeze

  USER_PROMPT = %(%s: "%s").freeze

  def perform(conversation, response, target_language = 'Svenska (sv)')
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
    nil
  end

  def messages
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: format(USER_PROMPT, 'query', question) },
      { role: 'user', content: format(USER_PROMPT, 'answer', response) }
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
