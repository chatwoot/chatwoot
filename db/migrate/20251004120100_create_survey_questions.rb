class CreateSurveyQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :survey_questions do |t|
      t.references :survey, null: false, foreign_key: true, index: true
      t.text :question_text, null: false
      t.integer :question_type, default: 0, null: false
      t.integer :input_type, default: 0
      t.integer :position, default: 0, null: false
      t.boolean :required, default: false, null: false

      t.timestamps
    end

    add_index :survey_questions, [:survey_id, :position]
  end
end
