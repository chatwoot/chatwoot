class Captain::AutomationConditionService
  ATTRIBUTE_KEY = 'captain_condition'.freeze
  OPERATORS = %w[detects does_not_detect].freeze
  THRESHOLD = 0.5
  CRITERIA = {
    'true' => 'The description clearly applies to what is being said.',
    'false' => 'The description does not apply, or applies only loosely or in passing.'
  }.freeze

  pattr_initialize [:conditions!, :conversation!, { message: nil }]

  # Answers every Captain condition of a rule in one request, keyed by the condition's index in the rule.
  def perform
    captain_conditions = conditions.each_with_index.select { |condition, _| condition['attribute_key'] == ATTRIBUTE_KEY }
    return {} if captain_conditions.empty?

    questions = captain_conditions.to_h { |condition, index| [index.to_s, question(condition)] }
    answers = Captain::SystemOneClient.new.ask(state: state, questions: questions)

    captain_conditions.to_h do |condition, index|
      detected = answers[index.to_s]['noul'] >= THRESHOLD
      [index, condition['filter_operator'] == 'detects' ? detected : !detected]
    end
  end

  private

  def question(condition)
    {
      type: 'noul',
      instructions: { description: condition['values'].first, question: question_text },
      criteria: CRITERIA
    }
  end

  def question_text
    if message
      'Does `description` apply to `latest_message`? Use `conversation.messages` as context.'
    else
      'Does `description` apply to the conversation in `conversation.messages`?'
    end
  end

  def state
    transcript = { conversation: { messages: Captain::ConversationTranscript.new(conversation: conversation).messages } }
    return transcript unless message

    transcript.merge(latest_message: Captain::ConversationTranscript.entry(message))
  end
end
