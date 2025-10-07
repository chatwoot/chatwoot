json.id @survey.id
json.name @survey.name
json.description @survey.description
json.active @survey.active
json.questions_count @survey.questions_count
json.created_at @survey.created_at
json.updated_at @survey.updated_at

json.questions @survey.survey_questions do |question|
  json.id question.id
  json.question_text question.question_text
  json.question_type question.question_type
  json.input_type question.input_type
  json.position question.position
  json.required question.required
  json.created_at question.created_at

  json.options question.survey_question_options do |option|
    json.id option.id
    json.option_text option.option_text
    json.position option.position
  end
end
