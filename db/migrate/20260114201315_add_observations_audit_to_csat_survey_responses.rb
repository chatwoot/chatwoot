class AddObservationsAuditToCsatSurveyResponses < ActiveRecord::Migration[7.1]
  def change
    add_column :csat_survey_responses, :review_notes_updated_at, :datetime
    add_reference :csat_survey_responses, :review_notes_updated_by, index: true
  end
end
