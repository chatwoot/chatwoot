class AddLoaderIdsInKnowledgeSourceWebsites < ActiveRecord::Migration[7.0]
  def change
    add_column :knowledge_source_websites, :loader_ids, :string, array: true, default: []
  end
end
