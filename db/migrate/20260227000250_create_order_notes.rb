class CreateOrderNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :order_notes do |t|
      t.text :content, null: false
      t.bigint :account_id, null: false
      t.bigint :order_id, null: false
      t.bigint :user_id
      t.timestamps
    end
    add_index :order_notes, :account_id
    add_index :order_notes, :order_id
    add_index :order_notes, :user_id
  end
end
