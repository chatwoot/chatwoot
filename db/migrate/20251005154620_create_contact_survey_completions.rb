class CreateContactSurveyCompletions < ActiveRecord::Migration[7.1]
  def change
    create_table :contact_survey_completions do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :survey, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.datetime :completed_at, null: false

      t.timestamps
    end

    add_index :contact_survey_completions, [:contact_id, :survey_id], unique: true, name: 'index_contact_survey_completions_unique'
    add_index :contact_survey_completions, [:account_id, :completed_at]
  end
end
