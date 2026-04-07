class AddInternalObservationsToCsatSurveyResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :csat_survey_responses, :csat_review_notes, :text
  end
end
