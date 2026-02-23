class CreateLocationHierarchies < ActiveRecord::Migration[7.0]
  def up
    create_table :location_hierarchies do |t|
      t.bigint :parent_location_id, null: false
      t.bigint :child_location_id, null: false
      t.bigint :account_id, null: false
      t.timestamps
    end

    add_index :location_hierarchies, [:parent_location_id, :child_location_id],
              unique: true, name: 'index_loc_hierarchies_on_parent_and_child'
    add_index :location_hierarchies, :child_location_id
    add_index :location_hierarchies, :account_id

    add_foreign_key :location_hierarchies, :locations, column: :parent_location_id
    add_foreign_key :location_hierarchies, :locations, column: :child_location_id
    add_foreign_key :location_hierarchies, :accounts

    # Data migration: copy existing parent_location_id relationships
    execute <<~SQL
      INSERT INTO location_hierarchies (parent_location_id, child_location_id, account_id, created_at, updated_at)
      SELECT parent_location_id, id, account_id, NOW(), NOW()
      FROM locations
      WHERE parent_location_id IS NOT NULL
    SQL

    remove_column :locations, :parent_location_id
  end

  def down
    add_column :locations, :parent_location_id, :bigint

    execute <<~SQL
      UPDATE locations l
      SET parent_location_id = (
        SELECT lh.parent_location_id
        FROM location_hierarchies lh
        WHERE lh.child_location_id = l.id
        LIMIT 1
      )
    SQL

    add_index :locations, :parent_location_id, name: 'index_locations_on_parent_location_id'
    add_index :locations, [:parent_location_id, :account_id], name: 'index_locations_on_parent_and_account'
    add_foreign_key :locations, :locations, column: :parent_location_id

    drop_table :location_hierarchies
  end
end
