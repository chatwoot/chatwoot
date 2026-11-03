# Turns a plain-English description into filter conditions for conversations or contacts.
# Jev only picks from the account's real fields and values, so every recommendation is a filter that exists.
# Whether it is the right one is for the person to decide before applying it.
class Captain::FilterRecommendationService
  MODEL = 'jev-latest'.freeze

  # How sure Jev must be that a field helps describe the records.
  MIN_RELEVANCE = 0.6
  # How sure Jev must be of a value before it is filled in.
  MIN_VALUE_PROBABILITY = 0.5
  # A value Jev is this sure of makes its field relevant by itself. A description such as
  # "billing" names a label value outright while saying nothing about labels.
  MIN_DECISIVE_VALUE_PROBABILITY = 0.8
  # How sure Jev must be of an operator before it replaces the field's first one.
  MIN_OPERATOR_PROBABILITY = 0.5

  MAX_RECOMMENDATIONS = 4
  CACHE_TTL = 7.days

  VALUELESS_OPERATORS = %w[is_present is_not_present].freeze
  OPERATOR_CRITERIA = {
    # "One specific value" pushed "pending or open" towards not_equal_to, so these name what `description` says.
    'equal_to' => 'The field is one of the values `description` names',
    'not_equal_to' => '`description` excludes the values it names, with words such as not, except or without',
    'contains' => 'The field contains the text `description` gives, such as a domain or part of a name',
    'does_not_contain' => '`description` excludes records whose field contains the text it gives',
    'is_present' => 'The field has any value',
    'is_not_present' => 'The field is empty'
  }.freeze
  # For text the general wording made "email from example.com" read as an exact match, so text fields say
  # whether `description` gives part of a value or all of it.
  TEXT_OPERATOR_CRITERIA = {
    'contains' => 'Part of the value, such as a domain, a word or a fragment, as in "email from example.com" or "email has acme"',
    'does_not_contain' => '`description` excludes values containing the text, as in "not from gmail.com"',
    'equal_to' => 'The whole value exactly, such as a full email address or a full name',
    'not_equal_to' => '`description` excludes one exact whole value'
  }.freeze
  RELEVANCE_CRITERIA = {
    'true' => 'The description clearly implies a condition on this field',
    'false' => 'The description says nothing about this field'
  }.freeze

  class Error < StandardError; end

  # `field_set` lists the fields to consider and names the records they filter,
  # such as Captain::ConversationFilterFields or Captain::ContactFilterFields.
  pattr_initialize [:account!, :field_set!, :query!]

  # Returns at most MAX_RECOMMENDATIONS conditions, or nil when Jev is not configured or cannot answer.
  # A condition has the filter payload shape, except a date condition, which names a `date_preset`
  # (and `days` when the preset counts days) for the dashboard to turn into dates.
  def perform
    return if Captain::JevClient.api_key.blank?

    recommendations(cached_answers)
  rescue Captain::JevClient::HTTPError, Faraday::Error, JSON::ParserError, Error => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    nil
  end

  private

  def cached_answers
    cache_key = "captain:filter_recommendations:#{Digest::SHA256.hexdigest([MODEL, questions, state].to_json)}"
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { ask }
  end

  def ask
    body = Captain::JevClient.request_body(model: MODEL, state: state, questions: questions)
    response = Captain::JevClient.new(account_id: account.id, feature: 'filter_recommendations').call(body: body)
    answers = response['answers'] if response.is_a?(Hash)
    raise Error, 'Jev returned an invalid response' unless answers.is_a?(Hash)

    answers
  end

  def state
    state = { description: query }
    fields.any? { |field| field[:text] } ? state.merge(words: Captain::FilterTextSpan.word_list(query)) : state
  end

  def fields
    @fields ||= field_set.all
  end

  def subject
    field_set.subject
  end

  def questions
    @questions ||= begin
      questions = fields.each_with_index.with_object({}) do |(field, index), field_questions|
        add_field_questions(field_questions, field, index)
      end
      questions[Captain::FilterDatePreset::DAY_COUNT_KEY] = Captain::FilterDatePreset.day_count_question if fields.any? { |field| field[:date] }
      questions
    end
  end

  def add_field_questions(questions, field, index)
    questions["relevant_#{index}"] = relevance_question(field)
    return questions.merge!(date_preset(field, index).questions) if field[:date]

    questions["operator_#{index}"] = operator_question(field) if field[:operators].size > 1
    return questions.merge!(text_span(field, index).questions) if field[:text]

    add_value_questions(questions, field, index)
    questions.merge!(Captain::FilterRange.new(field: field, index: index).questions) if field[:ordered]
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
      instructions: "Would the #{subject} described by `description` be found by filtering on \"#{field[:label]}\"?",
      criteria: RELEVANCE_CRITERIA
    }
  end

  def operator_question(field)
    {
      type: 'choice',
      instructions: "If the #{subject} described by `description` are filtered on \"#{field[:label]}\", " \
                    'which comparison does `description` imply?',
      criteria: (field[:text] ? TEXT_OPERATOR_CRITERIA : OPERATOR_CRITERIA).slice(*field[:operators])
    }
  end

  def value_question(field)
    criteria = { 'none' => '`description` does not say which' }
    field[:options].each_with_index { |option, index| criteria["option_#{index}"] = option[:label] }

    {
      type: 'choice',
      instructions: "If the #{subject} described by `description` are filtered on \"#{field[:label]}\", " \
                    'which value does `description` imply?',
      criteria: criteria
    }
  end

  def option_question(field, option)
    {
      type: 'noul',
      instructions: "Does `description` ask for #{subject} whose \"#{field[:label]}\" is \"#{option[:label]}\"?",
      criteria: {
        'true' => "`description` names \"#{option[:label]}\" or clearly means it",
        'false' => "`description` does not mention \"#{option[:label]}\", or excludes it"
      }
    }
  end

  def recommendations(answers)
    scored = fields.each_with_index.filter_map do |field, index|
      value_probabilities = option_probabilities(field, answers, index)
      relevance = [Captain::JevAnswers.probability(answers["relevant_#{index}"], 'noul'), decisive_value_probability(value_probabilities)].max
      next if relevance < MIN_RELEVANCE

      { relevance: relevance, condition: condition(field, index, answers, value_probabilities) }
    end

    scored.max_by(MAX_RECOMMENDATIONS) { |entry| entry[:relevance] }.pluck(:condition)
  end

  def condition(field, index, answers, value_probabilities)
    return date_preset(field, index).condition(answers) if field[:date]

    range = Captain::FilterRange.new(field: field, index: index).values(answers) if field[:ordered]
    # A range already says which levels to keep. Jev reads "below" as an exclusion, so its operator is ignored.
    operator = range ? 'equal_to' : implied_operator(field, answers["operator_#{index}"])
    values = if VALUELESS_OPERATORS.include?(operator)
               []
             elsif field[:text]
               text_span(field, index).values(answers)
             else
               range || implied_values(field, value_probabilities)
             end
    { attribute_key: field[:key], filter_operator: operator, values: values }
  end

  def text_span(field, index)
    Captain::FilterTextSpan.new(field: field, index: index, query: query)
  end

  def date_preset(field, index)
    Captain::FilterDatePreset.new(field: field, index: index, query: query)
  end

  # The operator Jev is confident the description implies, or the field's first one.
  def implied_operator(field, answer)
    choice = Captain::JevAnswers.confident_choice(answer, MIN_OPERATOR_PROBABILITY)
    field[:operators].include?(choice) ? choice : field[:operators].first
  end

  # Jev's probability for each of the field's options, in option order.
  def option_probabilities(field, answers, index)
    field[:options].each_index.map do |option_index|
      if field[:multiple]
        Captain::JevAnswers.probability(answers["value_#{index}_#{option_index}"], 'noul')
      else
        Captain::JevAnswers.probability(answers["value_#{index}"].try(:[], 'probabilities'), "option_#{option_index}")
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
end

Captain::FilterRecommendationService.prepend_mod_with('Captain::FilterRecommendationService')
