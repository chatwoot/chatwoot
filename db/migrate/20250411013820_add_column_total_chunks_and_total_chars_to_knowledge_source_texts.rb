class AddColumnTotalChunksAndTotalCharsToKnowledgeSourceTexts < ActiveRecord::Migration[7.0]
  def change
    add_column :knowledge_source_texts, :total_chunks, :integer, default: 0, null: false
    add_column :knowledge_source_texts, :total_chars, :integer, default: 0, null: false
  end
end
