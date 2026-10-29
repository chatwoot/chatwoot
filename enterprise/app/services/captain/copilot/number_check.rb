# Finds the numbers in a draft answer that no tool result supports. A number is supported when it appears in the known
# texts, or follows from known numbers by a sum, difference, ratio, percentage, percentage change or a conversion from
# seconds, at the precision the draft shows. A supported number joins the known ones, so an answer can show its working.
#
# Dates, times, links, conversation references and list markers are not checked, because they are not counts or
# measures. Questions back to the agent make no claim, so sentences that end with a question mark are not checked.
class Captain::Copilot::NumberCheck
  NUMBER = /(?<![\w.])\d{1,3}(?:,\d{3})+(?:\.\d+)?(?![\w])|(?<![\w.])\d+(?:\.\d+)?(?![\w])/
  # The draft is in the account's language, so its digit groups may be joined by a dot, comma, apostrophe or space, as in
  # 1.899, 1 899,50 or 1,23,456. Tool results are machine output, so they are read with NUMBER.
  DRAFT_NUMBER = /(?<![\w.,'’])(?:\d{1,3}(?:\p{Zs}\d{3})+(?:[.,]\d+)?|\d+(?:[.,'’]\d+)*)(?![\w])/
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

  # Link targets, dates and references are known as themselves but never combined, so the IDs and dates of an earlier
  # table do not make most made-up shares match something.
  def initialize(known_texts)
    texts = known_texts.map(&:to_s)
    measures = (numbers_in(texts.map { |text| strip(text) }) + UNITS).uniq
    @paired = measures.first(MAX_PAIRED)
    @candidates = Set.new(numbers_in(texts))
    measures.each { |value| add_single(value) }
    @paired.combination(2).each { |first, second| add_pair(first, second) }
  end

  def unsupported(draft)
    gaps = []
    sentences(draft).each do |sentence|
      strip(sentence).scan(DRAFT_NUMBER).each do |number|
        value = readings(number).find { |reading| supported?(reading) }
        value ? learn(value.to_f) : gaps << { number: number, sentence: sentence.strip }
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

  def numbers_in(texts)
    texts.flat_map { |text| text.scan(NUMBER) }.map { |match| match.delete(',').to_f }
  end

  # A draft number with its last separator as the decimal point, and also as a whole number when the separators could
  # group thousands, as in 1.899 or 1,23,456.
  def readings(token)
    *groups, last = token.split(/\D/)
    return [last] if groups.empty?

    decimal = "#{groups.join}.#{last}"
    thousands = last.size == 3 && groups.first.match?(/\A[1-9]\d{0,2}\z/) && groups.drop(1).all? { |group| group.size.between?(2, 3) }
    thousands ? [groups.join + last, decimal] : [decimal]
  end

  def supported?(shown)
    precision = shown.include?('.') ? shown.split('.').last.size : 0
    @candidates.any? { |candidate| (candidate.round(precision) - shown.to_f).abs < 1e-9 }
  end

  def learn(value)
    add_single(value)
    @paired.each { |other| add_pair(value, other) }
    @paired << value
  end

  def add_single(value)
    @candidates << value
    CONVERSIONS.each { |unit| @candidates << (value / unit) }
  end

  def add_pair(first, second)
    @candidates << (first + second) << (first - second).abs
    [[first, second], [second, first]].each do |part, whole|
      next if whole.zero?

      @candidates << (part / whole) << (part / whole * 100) << ((part - whole).abs / whole * 100)
    end
  end
end
