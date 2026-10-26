# Finds the numbers in a draft answer that no tool result supports. A number is supported when it appears in the known
# texts (tool results, the agent's messages, earlier answers), or follows from known numbers by a sum, difference, ratio,
# percentage, percentage change or a conversion from seconds, after rounding to the precision the draft shows. A number
# the draft supports joins the known ones, so an answer can show its working, such as a sum and then its share.
#
# Dates, times, links, conversation references and list markers are not checked, because they are not counts or
# measures. Questions back to the agent make no claim, so sentences that end with a question mark are not checked.
class Captain::Copilot::NumberCheck
  NUMBER = /(?<![\w.])\d{1,3}(?:,\d{3})+(?:\.\d+)?(?![\w])|(?<![\w.])\d+(?:\.\d+)?(?![\w])/
  # Removed from the draft before numbers are read.
  NOT_MEASURES = [
    /\]\([^)]*\)/,                                      # link targets
    /\d{4}-\d{2}-\d{2}(?:[T ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?)?/, # dates and times
    /\b\d{1,2}:\d{2}\b/,                                # clock times
    /#\d+/,                                             # conversation references
    /^\s*\d+[.)]\s/                                     # list markers
  ].freeze
  QUESTION_MARKS = /[?？؟]\s*\z/
  # Seconds in a minute, hour and day, hours in a day, days in a week, and a hundred for percentages.
  UNITS = [60, 3600, 86_400, 24, 7, 100].freeze
  CONVERSIONS = [60, 3600, 86_400].freeze
  # Pairs grow with the square of the known numbers, so sums and ratios use at most this many of them.
  MAX_PAIRED = 200

  def initialize(known_texts)
    known = (known_texts.flat_map { |text| numbers_in(text.to_s) }.map(&:to_f) + UNITS).uniq
    @paired = known.first(MAX_PAIRED)
    @candidates = Set.new
    known.each { |value| add_single(value) }
    @paired.combination(2).each { |first, second| add_pair(first, second) }
  end

  # Each unsupported number with the sentence it is in.
  def unsupported(draft)
    gaps = []
    sentences(draft).each do |sentence|
      numbers_in(strip(sentence)).each do |number|
        supported?(number) ? learn(number.to_f) : gaps << { number: number, sentence: sentence.strip }
      end
    end
    gaps.uniq { |gap| gap[:number] }
  end

  private

  def sentences(text)
    text.split(/(?<=[.!?。！？])\s+|\n+/).reject { |sentence| sentence.blank? || sentence.match?(QUESTION_MARKS) }
  end

  def strip(text)
    NOT_MEASURES.reduce(text) { |stripped, pattern| stripped.gsub(pattern, ' ') }
  end

  def numbers_in(text)
    text.scan(NUMBER).map { |match| match.delete(',') }
  end

  # A candidate matches when it rounds to the number at the precision the draft shows.
  def supported?(shown)
    precision = shown.include?('.') ? shown.split('.').last.size : 0
    @candidates.any? { |candidate| (candidate.round(precision) - shown.to_f).abs < 1e-9 }
  end

  # A supported number from the draft, combined with the known numbers, supports the numbers after it.
  def learn(value)
    add_single(value)
    @paired.each { |other| add_pair(value, other) }
    @paired << value
  end

  def add_single(value)
    @candidates << value
    CONVERSIONS.each { |unit| @candidates << (value / unit) }
  end

  # Sums, differences, ratios, percentages and percentage changes of two numbers, either way round.
  def add_pair(first, second)
    @candidates << (first + second) << (first - second).abs
    [[first, second], [second, first]].each do |part, whole|
      next if whole.zero?

      @candidates << (part / whole) << (part / whole * 100) << ((part - whole).abs / whole * 100)
    end
  end
end
