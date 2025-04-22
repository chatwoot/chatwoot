class AddColumnContentToKnowledgeSourceWebsites < ActiveRecord::Migration[7.0]
  def change
    add_column :knowledge_source_websites, :content, :text, null: false, default: ''
  end
end
