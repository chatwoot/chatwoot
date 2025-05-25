class CreateDatasetConfigurations < ActiveRecord::Migration[7.0]
  def change
    create_table :dataset_configurations do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :platform, null: false # 'facebook', 'instagram', 'meta'
      t.string :pixel_id, null: false
      t.string :access_token, null: false
      t.string :test_event_code
      t.string :default_event_name, default: 'Lead'
      t.decimal :default_event_value, precision: 10, scale: 2, default: 0
      t.string :default_currency, default: 'USD'
      t.boolean :auto_send_conversions, default: true
      t.boolean :enabled, default: true
      t.json :additional_config
      t.text :description
      
      t.timestamps
    end

    add_index :dataset_configurations, [:account_id, :platform]
    add_index :dataset_configurations, :pixel_id
  end
end
