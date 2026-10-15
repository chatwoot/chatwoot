# Numbers in Copilot's answer that appear in no tool result and no agent message, such as a count the model tallied
# from rows it read. The model is asked once per turn to source or drop them, and the ones still unsourced stay in the
# answer with a visible note. Record references, dates, times, years and list markers are ignored, because they are not
# claims about how much of something there is.
class Captain::Copilot::UnsourcedNumbers
  IGNORED = [
    /\]\([^)]*\)/,
    %r{https?://\S+},
    /#\d+/,
    /\b\d{4}-\d{2}(?:-\d{2})?(?:[T ][\d:.]+(?:Z|[+-]\d{2}:?\d{2})?)?/,
    /\b\d{1,2}:\d{2}(?::\d{2})?\b/,
    /^\s*\d+[.)]\s/
  ].freeze
  NUMBER = %r{(?<![\w.\-/])\d(?:[\d,.]*\d)?%?(?![\w/])}
  MAX_RATIO_TERMS = 300
  # Written without a comma, so a count such as 2,000 is still checked.
  YEAR = /\A(?:19|20)\d{2}\z/
  # Plain digits, or 1 to 3 digits followed by groups of three separated by the same comma or dot.
  INTEGER = '(?:\d+|[1-9]\d{0,2}([,.])\d{3}(?:\1\d{3})*)'.freeze
  WHOLE = /\A#{INTEGER}\z/
  # The decimal mark is the last comma or dot, and differs from the mark that groups thousands.
  DECIMAL = /\A#{INTEGER}(?!\1)[,.]\d+\z/

  # Each number as written, with the values it can stand for. Languages differ in whether a comma or a dot is the decimal
  # mark, so both are read: "1.234" is 1234 or 1.234, and "23,5%" is 23.5%. A number no convention reads, such as a
  # version like 3.5.2, is left out.
  def self.numbers_in(text)
    text = IGNORED.reduce(text.to_s) { |remaining, pattern| remaining.gsub(pattern, ' ') }
    text.scan(NUMBER).grep_v(YEAR).uniq.index_with { |number| readings(number) }.compact_blank
  end

  def self.in_text(text)
    numbers_in(text).values.flatten.to_set
  end

  # A decimal reading of "2,000" is left out, because 2 would let any count written in thousands pass.
  def self.readings(number)
    digits = number.delete('%')
    whole, _mark, fraction = digits.rpartition(/[,.]/)
    values = []
    values << digits.delete(',.') if digits.match?(WHOLE)
    values << "#{whole.delete(',.')}.#{fraction}" if digits.match?(DECIMAL) && !(digits.match?(WHOLE) && fraction.match?(/\A0+\z/))
    values.filter_map { |value| normalize(number.end_with?('%') ? "#{value}%" : value) }
  end

  def self.in_data(value)
    case value
    when Hash then value.values.reduce(Set.new) { |numbers, item| numbers | in_data(item) }
    when Array then value.reduce(Set.new) { |numbers, item| numbers | in_data(item) }
    when Numeric then Set[normalize(value.to_s)]
    when String then in_text(value)
    else Set.new
    end
  end

  # The numeric values tools returned, such as totals and counts, which a ratio in the answer may be built from.
  def self.counts_in(value)
    case value
    when Hash then value.values.flat_map { |item| counts_in(item) }
    when Array then value.flat_map { |item| counts_in(item) }
    when Numeric then value.positive? ? [value.to_f] : []
    else []
    end
  end

  def self.normalize(number)
    digits = number.delete(',%')
    digits = digits.sub(/\.?0+\z/, '') if digits.include?('.')
    return if digits.empty?

    number.end_with?('%') ? "#{digits}%" : digits
  end

  def initialize(run, token)
    @run = run
    @token = token
  end

  # The note asking the model to source the numbers in its draft, or nil when the draft needs none or this turn was
  # already checked.
  def note_for(draft)
    return if @run.context.key?('unsourced_numbers_in_draft')

    numbers = find(draft)
    @run.with_lease(@token) { @run.update!(context: @run.context.merge('unsourced_numbers_in_draft' => numbers)) }
    Captain::PromptRenderer.render('copilot_unsourced_numbers', numbers: numbers.join(', ')) if numbers.any?
  end

  # The numbers still unsourced in the answer the model gave after the note.
  def in_answer(answer)
    @run.context['unsourced_numbers_in_draft'].present? ? find(answer) : []
  end

  private

  def find(answer)
    given = sources
    known = self.class.in_data(given)
    terms = self.class.counts_in(given).uniq.first(MAX_RATIO_TERMS)
    # A percentage must appear as one or be a ratio of returned numbers; a count with the same digits is not a source.
    unsourced = self.class.numbers_in(answer).reject { |_, values| values.any? { |value| known.include?(value) || ratio?(value, terms) } }
    unsourced.sort_by { |_, values| values.first.to_f }.map(&:first)
  end

  # What the model was told in this thread up to this turn: the agent's messages and every tool result. Tool arguments
  # are left out, because the model wrote them. Read on every check, so numbers from a recount count as sources.
  def sources
    messages = @run.copilot_thread.copilot_messages.user.where(CopilotMessage.arel_table[:id].lteq(@run.copilot_message_id))
    results = CopilotToolCall.where(copilot_run: @run.copilot_thread.copilot_runs.turn).pluck(:result)
    [messages.map(&:message), results, @run.user_id, @run.account_id]
  end

  # A decimal or percentage that equals a ratio of two numbers the tools returned, rounded as the answer writes it, is
  # arithmetic on sourced numbers. Whole numbers must appear as they are, because small counts can be made from almost
  # any pair of small numbers.
  def ratio?(number, terms)
    percent = number.end_with?('%')
    value = number.delete('%')
    return false unless percent || value.include?('.')

    places = value[/\.(\d+)/, 1].to_s.size
    scale = percent ? 100.0 : 1.0
    terms.any? { |numerator| terms.any? { |denominator| ((scale * numerator / denominator).round(places) - value.to_f).abs < 1e-9 } }
  end
end
