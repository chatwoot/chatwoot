# Group answers by survey
surveys_hash = @survey_answers.group_by { |answer| answer.survey_question.survey }

json.array! surveys_hash.keys do |survey|
  json.survey_id survey.id
  json.survey_name survey.name
  json.survey_description survey.description

  # Check if survey is completed
  completion = @contact.contact_survey_completions.find_by(survey: survey)
  json.is_completed completion.present?
  json.completed_at completion&.completed_at

  json.answers surveys_hash[survey] do |answer|
    json.id answer.id
    json.question_text answer.survey_question.question_text
    json.question_type answer.survey_question.question_type
    json.answer_text answer.answer_text

    if answer.survey_question_option
      json.selected_option do
        json.id answer.survey_question_option.id
        json.option_text answer.survey_question_option.option_text
      end
    else
      json.selected_option nil
    end

    json.created_at answer.created_at
  end
end
