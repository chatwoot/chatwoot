class CreateCarts < ActiveRecord::Migration[7.0]
  def change
    create_table :carts do |t|
      t.references :account, null: false, foreign_key: true
      t.string :status
      t.timestamp :created_at
      t.timestamp :updated_at

      t.timestamps
    end
  end
end
