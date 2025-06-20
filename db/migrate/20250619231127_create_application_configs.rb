class CreateApplicationConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :application_configs do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true

      t.string :name, null: false, limit: 100
      t.text :url, null: false
      t.text :description
      t.string :status, null: false, default: 'active'
      t.boolean :open_new_tab, default: true
      t.json :custom_params
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :application_configs, [:account_id, :name], unique: true
    add_index :application_configs, [:account_id, :status]
    add_index :application_configs, :last_used_at
  end
end
