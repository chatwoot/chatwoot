class CreateLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.text :description
      t.string :type_name # Note: NOT using 'type' to avoid Rails STI conflict
      t.references :parent_location, foreign_key: { to_table: :locations }, index: true
      t.references :account, null: false, foreign_key: true, index: true

      t.timestamps
    end

    # Composite index for efficient searches by account and name
    add_index :locations, [:account_id, :name], name: 'index_locations_on_account_id_and_name'

    # Composite index for efficient hierarchical queries
    add_index :locations, [:parent_location_id, :account_id], name: 'index_locations_on_parent_and_account'
  end
end
