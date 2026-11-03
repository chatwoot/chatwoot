# Turns a plain-English description of conversations into conversation filter conditions.
# Jev only picks from the account's real fields and values, so every recommendation is a filter that exists.
# Whether it is the right one is for the person to decide before applying it.
class Captain::ConversationFilterRecommendationService
  MODEL = 'jev-latest'.freeze

  # How sure Jev must be that a field helps describe the conversations.
  MIN_RELEVANCE = 0.6
  # How sure Jev must be of a value before it is filled in.
  MIN_VALUE_PROBABILITY = 0.5
  # A value Jev is this sure of makes its field relevant by itself. A description such as
  # "billing" names a label value outright while saying nothing about labels.
  MIN_DECISIVE_VALUE_PROBABILITY = 0.8
  # How sure Jev must be of an operator before it replaces the field's first one.
  MIN_OPERATOR_PROBABILITY = 0.5

  MAX_RECOMMENDATIONS = 4
  MAX_DAYS = 998
  CACHE_TTL = 7.days

  VALUELESS_OPERATORS = %w[is_present is_not_present].freeze
  OPERATOR_CRITERIA = {
    # "One specific value" pushed "pending or open" towards not_equal_to, so these name what `description` says.
    'equal_to' => 'The field is one of the values `description` names',
    'not_equal_to' => '`description` excludes the values it names, with words such as not, except or without',
    'is_present' => 'The field has any value',
    'is_not_present' => 'The field is empty'
  }.freeze
  # Date fields compare against today minus the number of days in the description.
  DATE_OPERATOR_CRITERIA = {
    'is_greater_than' => 'Recent: within the last number of days `description` gives',
    'days_before' => 'Old: more than the number of days ago that `description` gives'
  }.freeze
  RELEVANCE_CRITERIA = {
    'true' => 'The description clearly implies a condition on this field',
    'false' => 'The description says nothing about this field'
  }.freeze

  class Error < StandardError; end

  pattr_initialize [:account!, :user!, :query!]

  # Returns at most MAX_RECOMMENDATIONS conditions in the conversation filter payload shape,
  # or nil when Jev is not configured or cannot answer.
  def perform
    return if Captain::JevClient.api_key.blank?

    recommendations(cached_answers)
  rescue Captain::JevClient::HTTPError, Faraday::Error, JSON::ParserError, Error => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    nil
  end

  private

  def cached_answers
    cache_key = "captain:conversation_filter_recommendations:#{Digest::SHA256.hexdigest([MODEL, questions, state].to_json)}"
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { ask }
  end

  def ask
    body = Captain::JevClient.request_body(model: MODEL, state: state, questions: questions)
    response = Captain::JevClient.new(account_id: account.id, feature: 'conversation_filter_recommendations').call(body: body)
    answers = response['answers'] if response.is_a?(Hash)
    raise Error, 'Jev returned an invalid response' unless answers.is_a?(Hash)

    answers
  end

  def state
    { description: query }
  end

  def fields
    @fields ||= Captain::ConversationFilterFields.new(account: account, user: user).all
  end

  def questions
    @questions ||= fields.each_with_index.with_object({}) do |(field, index), questions|
      questions["relevant_#{index}"] = relevance_question(field)
      questions["operator_#{index}"] = operator_question(field) if field[:operators].size > 1
      add_value_questions(questions, field, index)
      add_range_questions(questions, field, index) if field[:ordered]
    end
  end

  # A field that takes several values gets one yes/no question per option, so "pending or open" can pick both.
  # A single choice cannot: Jev splits its probability between the named options and none of them wins.
  def add_value_questions(questions, field, index)
    return if field[:options].empty?
    return questions["value_#{index}"] = value_question(field) unless field[:multiple]

    field[:options].each_with_index do |option, option_index|
      questions["value_#{index}_#{option_index}"] = option_question(field, option)
    end
  end

  def relevance_question(field)
    {
      type: 'noul',
      instructions: "Would the support conversations described by `description` be found by filtering on \"#{field[:label]}\"?",
      criteria: RELEVANCE_CRITERIA
    }
  end

  def operator_question(field)
    {
      type: 'choice',
      instructions: "If the conversations described by `description` are filtered on \"#{field[:label]}\", " \
                    'which comparison does `description` imply?',
      criteria: (field[:date] ? DATE_OPERATOR_CRITERIA : OPERATOR_CRITERIA).slice(*field[:operators])
    }
  end

  def value_question(field)
    criteria = { 'none' => '`description` does not say which' }
    field[:options].each_with_index { |option, index| criteria["option_#{index}"] = option[:label] }

    {
      type: 'choice',
      instructions: "If the conversations described by `description` are filtered on \"#{field[:label]}\", " \
                    'which value does `description` imply?',
      criteria: criteria
    }
  end

  def add_range_questions(questions, field, index)
    questions.merge!(Captain::ConversationFilterRange.new(field: field, index: index).questions)
  end

  def option_question(field, option)
    {
      type: 'noul',
      instructions: "Does `description` ask for conversations whose \"#{field[:label]}\" is \"#{option[:label]}\"?",
      criteria: {
        'true' => "`description` names \"#{option[:label]}\" or clearly means it",
        'false' => "`description` does not mention \"#{option[:label]}\", or excludes it"
      }
    }
  end

  def recommendations(answers)
    scored = fields.each_with_index.filter_map do |field, index|
      value_probabilities = option_probabilities(field, answers, index)
      relevance = [probability(answers["relevant_#{index}"], 'noul'), decisive_value_probability(value_probabilities)].max
      next if relevance < MIN_RELEVANCE

      range = range_values(field, index, answers)
      # A range already says which levels to keep. Jev reads "below" as an exclusion, so its operator is ignored.
      operator = range ? 'equal_to' : implied_operator(field, answers["operator_#{index}"])
      values = condition_values(field, operator, value_probabilities, range)
      { relevance: relevance, condition: { attribute_key: field[:key], filter_operator: operator, values: values } }
    end

    scored.max_by(MAX_RECOMMENDATIONS) { |entry| entry[:relevance] }.pluck(:condition)
  end

  def condition_values(field, operator, value_probabilities, range_values)
    return [] if VALUELESS_OPERATORS.include?(operator)
    return [number_in_query].compact if operator == 'days_before'
    return [days_ago_date].compact if field[:date]

    range_values || implied_values(field, value_probabilities)
  end

  def range_values(field, index, answers)
    Captain::ConversationFilterRange.new(field: field, index: index).values(answers) if field[:ordered]
  end

  # The operator Jev is confident the description implies, or the field's first one.
  def implied_operator(field, answer)
    choice = choice_of(answer)
    return choice if field[:operators].include?(choice) && choice_probability(answer) >= MIN_OPERATOR_PROBABILITY

    field[:operators].first
  end

  # Jev's probability for each of the field's options, in option order.
  def option_probabilities(field, answers, index)
    field[:options].each_index.map do |option_index|
      if field[:multiple]
        probability(answers["value_#{index}_#{option_index}"], 'noul')
      else
        probability(answers["value_#{index}"].try(:[], 'probabilities'), "option_#{option_index}")
      end
    end
  end

  # Every option Jev is confident of for a multi-value field, or the most likely one for a single-value field.
  def implied_values(field, value_probabilities)
    confident = field[:options].zip(value_probabilities).select { |_, value_probability| value_probability >= MIN_VALUE_PROBABILITY }
    confident = confident.max_by(1) { |_, value_probability| value_probability } unless field[:multiple]
    confident.map { |option, _| option[:value] }
  end

  def decisive_value_probability(value_probabilities)
    highest = value_probabilities.max.to_f
    highest >= MIN_DECISIVE_VALUE_PROBABILITY ? highest : 0.0
  end

  def days_ago_date
    days = number_in_query
    (Time.zone.today - days).iso8601 if days
  end

  # Jev picks from options and does not read numbers. When the description holds exactly one
  # whole number in the allowed range, that is the number of days meant.
  def number_in_query
    numbers = query.delete(',').scan(/(?<![\w.])\d+(?:\.\d+)?(?![\w.])/)
    return unless numbers.one?

    days = Integer(numbers.first, 10, exception: false)
    days if days&.between?(1, MAX_DAYS)
  end

  def choice_of(answer)
    choice = answer['choice'] if answer.is_a?(Hash)
    choice if choice.is_a?(String)
  end

  def choice_probability(answer)
    probability(answer['probabilities'], choice_of(answer)) if answer.is_a?(Hash)
  end

  def probability(hash, key)
    value = hash[key] if hash.is_a?(Hash) && key
    value.is_a?(Numeric) ? value.to_f : 0.0
  end
end

Captain::ConversationFilterRecommendationService.prepend_mod_with('Captain::ConversationFilterRecommendationService')
