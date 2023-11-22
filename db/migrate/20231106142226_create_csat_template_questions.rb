class CreateCsatTemplateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :csat_template_questions do |t|
      t.references :csat_template, null: false
      t.text :content
      t.timestamps
    end
  end
end
