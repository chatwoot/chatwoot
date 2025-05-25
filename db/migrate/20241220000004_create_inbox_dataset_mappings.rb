class CreateInboxDatasetMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :inbox_dataset_mappings do |t|
      t.references :inbox, null: false, foreign_key: true
      t.references :dataset_configuration, null: false, foreign_key: true
      t.boolean :enabled, default: true
      t.json :override_config # Override specific settings for this inbox
      
      t.timestamps
    end

    add_index :inbox_dataset_mappings, [:inbox_id, :dataset_configuration_id], 
              unique: true, name: 'index_inbox_dataset_unique'
  end
end
