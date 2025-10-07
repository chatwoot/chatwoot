class CreateSurveyAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :survey_answers do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :survey_question, null: false, foreign_key: true
      t.references :survey_question_option, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.text :answer_text

      t.timestamps
    end

    add_index :survey_answers, [:contact_id, :survey_question_id], unique: true
    add_index :survey_answers, [:account_id, :created_at]
  end
end
