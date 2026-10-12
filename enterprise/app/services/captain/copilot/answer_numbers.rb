# Finds numbers in an answer that appear in no tool result and no agent message, such as a count the model tallied
# from rows it read. Record references, dates, times, years and list markers are ignored, because they are not claims
# about how much of something there is.
class Captain::Copilot::AnswerNumbers
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

  def initialize(answer, sources)
    @answer = answer
    @sources = sources
  end

  def unsupported
    known = self.class.in_data(@sources)
    terms = self.class.counts_in(@sources).uniq.first(MAX_RATIO_TERMS)
    self.class.in_text(@answer).reject { |number| known.include?(number.delete('%')) || ratio?(number, terms) }.sort_by(&:to_f)
  end

  private

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
