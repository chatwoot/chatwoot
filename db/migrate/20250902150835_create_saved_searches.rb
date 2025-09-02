class CreateSavedSearches < ActiveRecord::Migration[7.0]
  def change
    create_table :saved_searches do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :search_type, default: 'all'
      t.text :query
      t.json :filters
      t.integer :usage_count, default: 0
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :saved_searches, [:account_id, :user_id]
    add_index :saved_searches, :search_type
    add_index :saved_searches, :last_used_at
  end
end