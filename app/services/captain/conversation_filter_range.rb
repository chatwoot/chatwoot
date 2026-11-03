# Reads a range such as "medium or higher" over a filter field whose options have an order.
# Jev's per-level answers miss levels that "or higher" only implies, and adding the order to those
# questions makes Jev include neighbouring levels the description does not ask for. So Jev answers
# which kind of range is meant and which level it starts from, and the option order decides the rest.
class Captain::ConversationFilterRange
  MIN_PROBABILITY = 0.5
  RANGE_CRITERIA = {
    'only' => 'Only the levels `description` names',
    'at_or_above' => 'The named level and every level above it, as in "or higher" or "at least"',
    'at_or_below' => 'The named level and every level below it, as in "or lower" or "at most"',
    'above' => 'Only levels above the named level, as in "above" or "higher than"',
    'below' => 'Only levels below the named level, as in "below" or "lower than"'
  }.freeze

  pattr_initialize [:field!, :index!]

  def questions
    {
      "range_#{index}" => {
        type: 'choice',
        instructions: "Which \"#{field[:label]}\" levels does `description` ask for?",
        criteria: RANGE_CRITERIA
      },
      "anchor_#{index}" => {
        type: 'choice',
        instructions: "Which \"#{field[:label]}\" level does the range in `description` start from?",
        criteria: field[:options].each_with_index.to_h { |option, option_index| ["option_#{option_index}", option[:label]] }
      }
    }
  end

  # The option values in the range, or nil when `description` lists levels rather than a range.
  def values(answers)
    range = confident_choice(answers["range_#{index}"])
    anchor = confident_choice(answers["anchor_#{index}"])&.delete_prefix('option_')&.to_i
    return if range.nil? || range == 'only' || anchor.nil?

    options_in_range(range, anchor).pluck(:value)
  end

  private

  def options_in_range(range, anchor)
    options = field[:options]
    case range
    when 'at_or_above' then options[anchor..]
    when 'above' then options[(anchor + 1)..]
    when 'at_or_below' then options[..anchor]
    when 'below' then options[...anchor]
    end
  end

  def confident_choice(answer)
    return unless answer.is_a?(Hash)

    choice = answer['choice']
    probability = answer.dig('probabilities', choice) if choice.is_a?(String)
    choice if probability.is_a?(Numeric) && probability >= MIN_PROBABILITY
  end
end
