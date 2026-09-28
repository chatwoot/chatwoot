class Captain::AutomationConditionService
  FEATURE = 'captain_classifier'.freeze
  ATTRIBUTE_KEY = 'captain_condition'.freeze
  OPERATORS = %w[detects does_not_detect].freeze
  THRESHOLD = 0.5
  CRITERIA = {
    'true' => 'The description clearly applies to what is being said.',
    'false' => 'The description does not apply, or applies only loosely or in passing.'
  }.freeze

  pattr_initialize [:conditions!, :conversation!, { message: nil }]

  # Answers every Captain condition of a rule in one request, keyed by the condition's index in the rule.
  # A condition Captain cannot judge is unmet whichever operator it uses, so the rest of the rule still decides.
  def perform
    return {} if captain_conditions.empty?
    return captain_conditions.to_h { |_, index| [index, false] } unless judgeable?

    questions = captain_conditions.to_h { |condition, index| [index.to_s, question(condition)] }
    answers = Captain::SystemOneClient.new.ask(state: state, questions: questions)

    captain_conditions.to_h { |condition, index| [index, met?(condition, answers[index.to_s])] }
  end

  private

  def captain_conditions
    @captain_conditions ||= conditions.each_with_index.select { |condition, _| condition['attribute_key'] == ATTRIBUTE_KEY }
  end

  def met?(condition, answer)
    detected = answer['noul'] >= THRESHOLD
    condition['filter_operator'] == 'detects' ? detected : !detected
  end

  def judgeable?
    return false unless conversation.account.feature_enabled?(FEATURE)

    message ? latest_message.present? : transcript.any?
  end

  def latest_message
    @latest_message ||= Captain::ConversationTranscript.entry(message)
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
    if message
      'Does `description` apply to `latest_message`? Use `conversation.messages` as context.'
    else
      'Does `description` apply to the conversation in `conversation.messages`?'
    end
  end

  def state
    state = { conversation: { messages: transcript } }
    message ? state.merge(latest_message: latest_message) : state
  end
end
