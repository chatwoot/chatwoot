class Captain::ConversationClassifierService
  MODEL = 'jev-latest'.freeze
  SYSTEM_ONE_PATH = '/v1/systemone'.freeze
  REQUEST_TIMEOUT = 15
  MESSAGE_LIMIT = 20
  STATE_TOKEN_BUDGET = 15_000
  CHARACTERS_PER_TOKEN = 4
  MAX_LABEL_SUGGESTIONS = 3
  LABEL_THRESHOLD = 0.5
  PRIORITY_CRITERIA = {
    'urgent' => 'The customer is blocked right now with serious impact: an outage, failing payments, a security issue, data loss, ' \
                'or a hard deadline within hours.',
    'high' => 'A significant problem affecting the customer\'s work or money that needs attention soon, but is not an emergency.',
    'medium' => 'A normal support request or question with no sign of time pressure.',
    'low' => 'Feedback, general information, or a casual message that can wait.'
  }.freeze
  LABEL_CRITERIA = {
    'true' => 'The messages are clearly about the topic this label names or describes.',
    'false' => 'The messages are about something else, or only mention the topic in passing.'
  }.freeze

  class Error < StandardError; end

  pattr_initialize [:conversation!]

  def labels
    candidates = conversation.account.labels.where.not(title: conversation.label_list).to_a
    return [] if candidates.empty?

    answers = ask(candidates.each_with_index.to_h { |label, index| [index.to_s, label_question(label)] })
    candidates.each_with_index
              .map { |label, index| { title: label.title, probability: answers[index.to_s]['noul'] } }
              .select { |suggestion| suggestion[:probability] >= LABEL_THRESHOLD }
              .max_by(MAX_LABEL_SUGGESTIONS) { |suggestion| suggestion[:probability] }
  end

  def priority
    answer = ask(
      priority: {
        type: 'choice',
        instructions: 'How urgently does the support team need to respond to the customer in `conversation.messages`?',
        criteria: PRIORITY_CRITERIA
      }
    )['priority']

    { priority: answer['choice'], confidence: answer['confidence'] }
  end

  private

  def label_question(label)
    {
      type: 'noul',
      instructions: {
        label: { name: label.title, description: label.description }.compact_blank,
        question: 'Does `label` describe what the customer is asking about or reporting in `conversation.messages`?'
      },
      criteria: LABEL_CRITERIA
    }
  end

  def ask(questions)
    response = HTTParty.post(
      "#{GlobalConfigService.load('CAPTAIN_OPENROUTER_DECISION_MODEL_ENDPOINT', nil)}#{SYSTEM_ONE_PATH}",
      headers: {
        'Authorization' => "Bearer #{GlobalConfigService.load('CAPTAIN_OPENROUTER_API_KEY', nil)}",
        'Content-Type' => 'application/json'
      },
      body: { model: MODEL, state: state, questions: questions }.to_json,
      timeout: REQUEST_TIMEOUT
    )
    raise Error, "Jev request failed with status #{response.code}: #{response.body}" unless response.success?

    response.parsed_response['answers']
  end

  def state
    { conversation: { messages: recent_messages } }
  end

  # Walks newest-first so the latest messages survive the token budget; returns chronological order.
  def recent_messages
    remaining = STATE_TOKEN_BUDGET * CHARACTERS_PER_TOKEN
    messages = []

    conversation.messages
                .where(message_type: [:incoming, :outgoing], private: false)
                .reorder(id: :desc)
                .limit(MESSAGE_LIMIT)
                .each do |message|
      content = message.content_for_llm
      next if content.blank? || message.deleted
      break if remaining <= 0

      text = content[0, remaining]
      remaining -= text.length
      messages.prepend({ sender: message.incoming? ? 'customer' : 'agent', text: text })
    end

    messages
  end
end
