# frozen_string_literal: true

# Makes Cart.created_by a polymorphic association
# This allows carts to be created by either Users or Aloo::Assistants
class MakeCartCreatedByPolymorphic < ActiveRecord::Migration[7.1]
  def up
    # Remove foreign key constraint to users table
    remove_foreign_key :carts, column: :created_by_id

    # Add created_by_type column for polymorphic association
    # Default to 'User' for existing records
    add_column :carts, :created_by_type, :string, default: 'User', null: false

    # Add composite index for polymorphic lookups
    add_index :carts, [:created_by_type, :created_by_id], name: 'index_carts_on_created_by'
  end

  def down
    # Remove composite index
    remove_index :carts, name: 'index_carts_on_created_by'

    # Remove type column
    remove_column :carts, :created_by_type

    # Re-add foreign key constraint
    add_foreign_key :carts, :users, column: :created_by_id
  end
end
