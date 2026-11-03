# Reads a free-text value, such as the domain in "email from chatwoot.com", out of the description.
# Jev cannot write text, so the description is split into numbered words that Jev can pick from,
# following jeveryword's approach (https://github.com/jkrup/jeveryword#custom-questions).
# Jev picks the first and the last word of the value, and the value is the original text between them.
class Captain::FilterTextSpan
  MIN_PROBABILITY = 0.5
  # Words split on whitespace, quotes and sentence punctuation. Emails, domains and phone numbers stay whole.
  WORD_PATTERN = /[^\s"“”‘’,;:!?()\[\]{}<>]+/
  TRAILING_PUNCTUATION = /[.']+\z/
  LEADING_PUNCTUATION = /\A'+/

  # Two readings of the same value. The broad reading alone took all of "incoming messages that mention refund",
  # and the strict reading alone kept "acme.com" in "acme.com asking for a demo". Their mistakes did not overlap,
  # so the value is the words both readings agree on.
  READINGS = {
    'broad' => 'Never pick the field\'s own name.',
    'strict' => 'The value leaves out words that only describe the records, the field or the comparison, ' \
                'such as messages, customers, mention, contains, from or with.'
  }.freeze

  pattr_initialize [:field!, :index!, :query!]

  # The words of the query with their character offsets.
  def self.words(query)
    query.to_enum(:scan, WORD_PATTERN).filter_map do
      match = Regexp.last_match
      text = match[0].sub(TRAILING_PUNCTUATION, '').sub(LEADING_PUNCTUATION, '')
      next if text.empty?

      start = match.begin(0) + match[0].index(text)
      { text: text, start: start, end: start + text.length }
    end
  end

  # One "id|word" line per word, for the request state.
  def self.word_list(query)
    words(query).each_with_index.map { |word, word_index| "#{word_index}|#{word[:text]}" }.join("\n")
  end

  def questions
    READINGS.each_with_object({}) do |(reading, rule), questions|
      questions["start_#{reading}_#{index}"] = span_question('FIRST', rule)
      questions["end_#{reading}_#{index}"] = span_question('LAST', rule)
    end
  end

  # The value `description` gives for the field, or no values when Jev is unsure or finds none.
  # When only one reading finds a value, that value is used. When both do but they share no words, there is no value.
  def values(answers)
    broad, strict = READINGS.keys.map { |reading| reading_range(answers, reading) }
    range = broad && strict ? overlap(broad, strict) : broad || strict
    range ? [query[range.first...range.last]] : []
  end

  private

  # The character range of one reading. When Jev is sure of only one end, the range is that one word.
  # For "Email has chatwoot" Jev was sure "chatwoot" ends the value but not that it starts it,
  # because one word does not look like an email.
  def reading_range(answers, reading)
    first = word_at(answers["start_#{reading}_#{index}"])
    last = word_at(answers["end_#{reading}_#{index}"])
    first ||= last
    last ||= first
    [first[:start], last[:end]] if first && first[:start] <= last[:start]
  end

  def overlap(range, other)
    start = [range.first, other.first].max
    finish = [range.last, other.last].min
    [start, finish] if start < finish
  end

  def span_question(position, rule)
    {
      type: 'choice',
      instructions: "`words` numbers the words of `description`. Which word is the #{position} word of the " \
                    "\"#{field[:label]}\" value that `description` gives, such as a word, a phrase, a name, a domain or a number? " \
                    "Pick none when `description` gives no \"#{field[:label]}\" value. #{rule}",
      criteria: criteria
    }
  end

  def criteria
    @criteria ||= { 'none' => '`description` gives no value for this field' }.merge(
      self.class.words(query).each_with_index.to_h { |word, word_index| [word_index.to_s, word[:text]] }
    )
  end

  def word_at(answer)
    choice = Captain::JevAnswers.confident_choice(answer, MIN_PROBABILITY)
    self.class.words(query)[Integer(choice, 10)] if choice&.match?(/\A\d+\z/)
  end
end
