class AddProductToContact < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :product_id, :integer, null: true
    add_column :contacts, :po_date, :datetime, null: true
    add_column :contacts, :po_value, :float, null: true
    add_column :contacts, :po_note, :string, null: true
  end
end
