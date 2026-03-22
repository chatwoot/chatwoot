class AddPortalReportIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :conversations, [:account_id, :created_at]
    add_index :csat_survey_responses, [:account_id, :created_at]
  end
end
