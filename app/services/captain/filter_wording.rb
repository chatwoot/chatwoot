# How Captain::FilterRecommendationService asks Jev about a filter field. A field set that includes it defines `subject`,
# the records it filters, such as "contacts".
module Captain::FilterWording
  RELEVANCE_CRITERIA = {
    'true' => 'The description clearly implies a condition on this field',
    'false' => 'The description says nothing about this field'
  }.freeze

  def relevance_question_text(field)
    "Would the #{subject} described by `description` be found by filtering on \"#{field[:label]}\"?"
  end

  def relevance_criteria
    RELEVANCE_CRITERIA
  end

  def operator_question_text(field)
    "If the #{subject} described by `description` are filtered on \"#{field[:label]}\", which comparison does `description` imply?"
  end

  def value_question_text(field)
    "If the #{subject} described by `description` are filtered on \"#{field[:label]}\", which value does `description` imply?"
  end

  def option_question_text(field, option)
    "Does `description` ask for #{subject} whose \"#{field[:label]}\" is \"#{option[:label]}\"?"
  end
end
