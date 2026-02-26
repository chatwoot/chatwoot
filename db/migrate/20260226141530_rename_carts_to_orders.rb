class RenameCartsToOrders < ActiveRecord::Migration[7.1]
  def change
    # Rename tables (metadata-only in PostgreSQL — instant, no data copy)
    rename_table :carts, :orders
    rename_table :cart_items, :order_items

    # Rename foreign key column in order_items
    rename_column :order_items, :cart_id, :order_id

    # Add delivery address snapshot (JSONB) to orders
    # Schema: { street, city, state, postal_code, country }
    add_column :orders, :delivery_address, :jsonb, default: {}
  end
end
