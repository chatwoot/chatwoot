class AttachTemplateAndQuestionToCsatResponse < ActiveRecord::Migration[7.0]
  def change
    add_reference :csat_survey_responses, :csat_template
    add_reference :csat_survey_responses, :csat_template_question
  end
end
