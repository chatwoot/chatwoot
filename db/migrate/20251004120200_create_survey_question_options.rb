class CreateSurveyQuestionOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :survey_question_options do |t|
      t.references :survey_question, null: false, foreign_key: true, index: true
      t.string :option_text, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :survey_question_options, [:survey_question_id, :position], name: 'index_survey_question_options_on_question_and_position'
  end
end
