class CreateMessagesCsatTemplateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :message_csat_template_questions do |t|
      t.references :message, unique: true, index: { name: :uniq_csat_question_messages_id }
      t.references :csat_template_question, index: { name: :index_messages_csat_question_id }
      t.integer :question_number
      t.timestamps
    end
  end
end
