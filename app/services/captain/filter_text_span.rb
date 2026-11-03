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
    {
      "start_#{index}" => span_question('FIRST'),
      "end_#{index}" => span_question('LAST')
    }
  end

  # The value `description` gives for the field, or no values when Jev is unsure or finds none.
  # When Jev is sure of only one end, the value is that one word. For "Email has chatwoot" Jev was
  # sure "chatwoot" ends the value but not that it starts it, because one word does not look like an email.
  def values(answers)
    first = word_at(answers["start_#{index}"])
    last = word_at(answers["end_#{index}"])
    first ||= last
    last ||= first
    return [] if first.nil? || first[:start] > last[:start]

    [query[first[:start]...last[:end]]]
  end

  private

  def span_question(position)
    {
      type: 'choice',
      instructions: "`words` numbers the words of `description`. Which word is the #{position} word of the " \
                    "\"#{field[:label]}\" value that `description` gives, such as a name, a domain or a number? " \
                    "Pick none when `description` gives no \"#{field[:label]}\" value. Never pick the field's own name.",
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
