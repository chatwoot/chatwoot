class Captain::ConversationClassifierService
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
    Captain::SystemOneClient.new.ask(
      state: { conversation: { messages: Captain::ConversationTranscript.new(conversation: conversation).messages } },
      questions: questions
    )
  end
end
