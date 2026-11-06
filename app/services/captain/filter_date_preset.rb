# Reads the time a description gives for a date field as one of a fixed set of presets.
# Jev picks the preset. The dashboard turns it into dates in the viewer's timezone, with weeks starting on Monday.
# Jev cannot read numbers from text, so a day count comes from the digits in the description,
# or else from a choice over common counts, which also covers counts written as words.
class Captain::FilterDatePreset
  MIN_PROBABILITY = 0.5
  MAX_DAYS = 998
  DAY_COUNT_KEY = 'day_count'.freeze
  DAY_COUNTS = ((1..31).to_a + [45, 60, 90]).freeze
  PRESETS = {
    'today' => 'Today',
    'yesterday' => 'Yesterday only',
    'this_week' => 'This calendar week so far',
    'last_week' => 'The previous calendar week',
    'this_month' => 'This calendar month so far',
    'last_month' => 'The previous calendar month',
    'this_year' => 'This calendar year so far',
    'last_n_days' => 'Within the last number of days `description` gives, such as "last 3 days"',
    'older_than_n_days' => 'More than the number of days ago that `description` gives, such as "older than 5 days" or "no activity for 5 days"',
    'older_than_week' => 'Older than a week, with no number of days given',
    'older_than_month' => 'Older than a month, with no number of days given',
    'none' => '`description` gives no time for this field'
  }.freeze
  # These presets are a day count the description does not spell out.
  FIXED_DAYS = { 'older_than_week' => 7, 'older_than_month' => 30 }.freeze
  COUNTED_PRESETS = %w[last_n_days older_than_n_days].freeze

  pattr_initialize [:field!, :index!, :query!]

  # Asked once per request, because the day count belongs to the description and not to a field.
  def self.day_count_question
    criteria = { 'none' => '`description` gives no number of days' }
    DAY_COUNTS.each { |count| criteria["days_#{count}"] = count == 1 ? '1 day' : "#{count} days" }
    { type: 'choice', instructions: 'How many days does `description` give, if any?', criteria: criteria }
  end

  def questions
    {
      "preset_#{index}" => {
        type: 'choice',
        instructions: "Which time does `description` give for \"#{field[:label]}\"?",
        criteria: PRESETS
      }
    }
  end

  # The condition for the field. A preset the description does not name leaves an empty date row to fill in.
  def condition(answers)
    preset = Captain::JevAnswers.confident_choice(answers["preset_#{index}"], MIN_PROBABILITY)
    return { attribute_key: field[:key], filter_operator: 'is_greater_than', values: [] } if preset.nil? || preset == 'none'
    return { attribute_key: field[:key], date_preset: 'older_than_n_days', days: FIXED_DAYS[preset] } if FIXED_DAYS.key?(preset)

    days = day_count(answers) if COUNTED_PRESETS.include?(preset)
    { attribute_key: field[:key], date_preset: preset, days: days }.compact
  end

  private

  def day_count(answers)
    digits_in_query || chosen_day_count(answers)
  end

  # When the description holds exactly one whole number in range, that is the number of days meant.
  def digits_in_query
    numbers = query.delete(',').scan(/(?<![\w.])\d+(?:\.\d+)?(?![\w.])/)
    return unless numbers.one?

    days = Integer(numbers.first, 10, exception: false)
    days if days&.between?(1, MAX_DAYS)
  end

  def chosen_day_count(answers)
    choice = Captain::JevAnswers.confident_choice(answers[DAY_COUNT_KEY], MIN_PROBABILITY)
    Integer(choice.delete_prefix('days_'), 10) if choice&.start_with?('days_')
  end
end
