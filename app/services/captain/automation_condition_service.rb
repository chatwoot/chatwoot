class Captain::AutomationConditionService
  MODEL = 'jev-latest'.freeze
  FEATURE = 'captain_classifier'.freeze
  ATTRIBUTE_KEY = 'captain_condition'.freeze
  OPERATORS = %w[detects does_not_detect].freeze
  MAX_DESCRIPTION_LENGTH = 500
  # About 2,000 tokens: with the transcript and the customer context the request stays well inside Jev's limit.
  LATEST_MESSAGE_LIMIT = 8_000
  THRESHOLD = 0.5
  CRITERIA = {
    'true' => 'The description clearly applies to what is being said.',
    'false' => 'The description does not apply, or applies only loosely or in passing.'
  }.freeze

  class Error < StandardError; end

  pattr_initialize [:conditions!, :conversation!, { message: nil }]

  # Answers every Captain condition of a rule in one request, keyed by the condition's index in the rule.
  # A condition Captain cannot judge is unmet whichever operator it uses, so the rest of the rule still decides.
  def perform
    return {} if captain_conditions.empty?
    return unmet unless judgeable?

    questions = captain_conditions.to_h { |condition, index| [index.to_s, question(condition)] }
    answers = ask(questions)

    captain_conditions.to_h { |condition, index| [index, met?(condition, answers[index.to_s])] }
  rescue Captain::JevClient::HTTPError, Faraday::Error, JSON::ParserError, Error => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    unmet
  end

  private

  def ask(questions)
    body = Captain::JevClient.request_body(model: MODEL, state: state, questions: questions)
    response = Captain::JevClient.new(account_id: conversation.account_id, conversation_id: conversation.display_id,
                                      feature: FEATURE).call(body: body)
    answers = response['answers'] if response.is_a?(Hash)
    raise Error, 'Jev returned an invalid response' unless answers.is_a?(Hash)

    answers
  end

  def unmet
    captain_conditions.to_h { |_, index| [index, false] }
  end

  def captain_conditions
    @captain_conditions ||= conditions.each_with_index.select { |condition, _| condition['attribute_key'] == ATTRIBUTE_KEY }
  end

  def met?(condition, answer)
    probability = answer.is_a?(Hash) ? answer['noul'] : nil
    raise Error, 'Jev returned an incomplete answer' unless probability.is_a?(Numeric)

    detected = probability >= THRESHOLD
    condition['filter_operator'] == 'detects' ? detected : !detected
  end

  def judgeable?
    return false unless conversation.account.feature_enabled?(FEATURE)

    message ? latest_message.present? : transcript.any?
  end

  def latest_message
    @latest_message ||= Captain::ConversationTranscript.entry(message, LATEST_MESSAGE_LIMIT)
  end

  def transcript
    @transcript ||= Captain::ConversationTranscript.new(conversation: conversation).messages
  end

  def question(condition)
    {
      type: 'noul',
      instructions: { description: condition['values'].first, question: question_text },
      criteria: CRITERIA
    }
  end

  def question_text
    subject = message ? '`latest_message`, with `conversation.messages` as context' : 'the conversation in `conversation.messages`'
    "Does `description` apply to #{subject}? `customer_context` holds what is known about the customer; do not assume facts it does not list."
  end

  def state
    state = {
      conversation: { messages: transcript },
      customer_context: Captain::CustomerContext.new(conversation: conversation).attributes
    }
    message ? state.merge(latest_message: latest_message) : state
  end
end
