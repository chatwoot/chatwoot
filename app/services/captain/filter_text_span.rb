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
  # A value never runs across a sentence. A rule's name and description are two sentences,
  # and a span that crossed them read "refund requests. Label incoming messages".
  SENTENCE_BREAK = /[.!?]\s/

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
  # When only one reading finds a value, that value is used. When both do, the value is the words they share,
  # or the text both found at different places in `description`. Otherwise there is no value.
  def values(answers)
    broad, strict = READINGS.keys.map { |reading| reading_range(answers, reading) }
    range = broad && strict ? overlap(broad, strict) || same_text(broad, strict) : broad || strict
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
    return unless first && first[:start] <= last[:start]
    # A word repeated in `description`, such as "bug" in "Add bug label. Add label bug, if a message contains bug",
    # was picked at its first place as the start and its last place as the end. Both picks mean that one word.
    return [last[:start], last[:end]] if first[:text].casecmp?(last[:text])
    return if query[first[:start]...last[:end]].match?(SENTENCE_BREAK)

    [first[:start], last[:end]]
  end

  def same_text(range, other)
    range if query[range.first...range.last].casecmp?(query[other.first...other.last])
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

  # The word Jev is confident of. A word repeated in `description` splits Jev's probability between its copies,
  # such as "bug" at 0.4, 0.1 and 0.4, so the copies of one word count together and the likeliest copy is used.
  def word_at(answer)
    copies = likeliest_word_copies(answer)
    copies.max_by(&:last).first if copies.sum(&:last) >= MIN_PROBABILITY
  end

  # The [word, probability] pairs of the word whose copies together have the highest probability.
  def likeliest_word_copies(answer)
    copies_by_word = word_probabilities(answer).group_by { |word, _| word[:text].downcase }.values
    copies_by_word.max_by { |copies| copies.sum(&:last) } || []
  end

  # [word, probability] for each word Jev gave a probability. The "none" answer is left out.
  def word_probabilities(answer)
    probabilities = answer.is_a?(Hash) && answer['probabilities'].is_a?(Hash) ? answer['probabilities'] : {}
    words = self.class.words(query)
    probabilities.filter_map do |choice, probability|
      word = words[choice.to_i] if choice.match?(/\A\d+\z/)
      [word, probability] if word && probability.is_a?(Numeric)
    end
  end
end
