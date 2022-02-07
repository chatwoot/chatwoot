class CreateCsatSurveyResponses < ActiveRecord::Migration[6.0]
  def change
    create_table :csat_survey_responses do |t|
      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true, index: { unique: true }
      t.integer :rating, null: false
      t.text :feedback_message
      t.references :contact, null: false, foreign_key: true
      t.references :assigned_agent, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
