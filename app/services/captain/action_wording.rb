# How Captain::FilterRecommendationService asks Jev about an automation action, where `description` names and
# describes a rule and a field's label says what the action does.
module Captain::ActionWording
  RELEVANCE_CRITERIA = {
    'true' => '`description` asks the rule to do this',
    'false' => '`description` does not ask the rule to do this'
  }.freeze

  def relevance_question_text(field)
    "Should the automation rule described by `description` do this: \"#{field[:label]}\"?"
  end

  def relevance_criteria
    RELEVANCE_CRITERIA
  end

  def value_question_text(field)
    "If the rule described by `description` does \"#{field[:label]}\", which value does `description` give for it?"
  end

  def option_question_text(field, option)
    "Does `description` ask the rule to do \"#{field[:label]}\" with \"#{option[:label]}\"?"
  end
end
