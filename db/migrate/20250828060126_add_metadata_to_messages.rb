class AddMetadataToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :metadata, :jsonb, default: []
    add_index :messages, :metadata, using: :gin
  end
end
