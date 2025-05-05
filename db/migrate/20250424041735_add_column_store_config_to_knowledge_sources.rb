class AddColumnStoreConfigToKnowledgeSources < ActiveRecord::Migration[7.0]
  def change
    add_column :knowledge_sources, :store_config, :jsonb, default: {}, null: false
  end
end
