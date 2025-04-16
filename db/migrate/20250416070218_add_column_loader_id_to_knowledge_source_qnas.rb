class AddColumnLoaderIdToKnowledgeSourceQnas < ActiveRecord::Migration[7.0]
  def change
    add_column :knowledge_source_qnas, :loader_id, :string, null: false, default: ''
  end
end
