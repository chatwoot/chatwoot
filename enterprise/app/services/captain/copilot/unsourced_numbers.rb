# Numbers in Copilot's answer that appear in no tool result and no agent message, such as a count the model tallied
# from rows it read. The model is asked once per turn to source or drop them, and the ones still unsourced stay in the
# answer with a visible note. Record references, dates, times, years and list markers are ignored, because they are not
# claims about how much of something there is.
class Captain::Copilot::UnsourcedNumbers
  NOTE = 'Automatic check, not a message from the agent: these numbers in your answer do not appear in any tool result: ' \
         '%<numbers>s. Every number must come from a tool result, or be a ratio or percentage of two numbers a tool returned. ' \
         'Recompute counts with get_data, using group_by for counts per period or value, or remove each number you cannot ' \
         'source. Then give the complete answer again.'.freeze
  IGNORED = [
    /\]\([^)]*\)/,
    %r{https?://\S+},
    /#\d+/,
    /\b\d{4}-\d{2}(?:-\d{2})?(?:[T ][\d:.]+(?:Z|[+-]\d{2}:?\d{2})?)?/,
    /\b\d{1,2}:\d{2}(?::\d{2})?\b/,
    /^\s*\d+[.)]\s/
  ].freeze
  NUMBER = %r{(?<![\w.\-/])\d(?:[\d,]*\d)?(?:\.\d+)?%?(?![\w/])}
  MAX_RATIO_TERMS = 300
  # Written without a comma, so a count such as 2,000 is still checked.
  YEAR = /\A(?:19|20)\d{2}\z/

  def self.in_text(text)
    text = IGNORED.reduce(text.to_s) { |remaining, pattern| remaining.gsub(pattern, ' ') }
    text.scan(NUMBER).grep_v(YEAR).filter_map { |number| normalize(number) }.to_set
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
    format(NOTE, numbers: numbers.join(', ')) if numbers.any?
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
    self.class.in_text(answer).reject { |number| known.include?(number) || ratio?(number, terms) }.sort_by(&:to_f)
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
