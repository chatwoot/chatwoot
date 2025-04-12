class ChangeTextColumnTypeInKnowledgeSourceTexts < ActiveRecord::Migration[7.0]
  def up
    change_column :knowledge_source_texts, :text, :text
  end

  def down
    change_column :knowledge_source_texts, :text, :string
  end
end
