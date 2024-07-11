class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price
      t.string :product_type
      t.text :description
      t.jsonb :details
      t.timestamp :created_at
      t.timestamp :updated_at

      t.timestamps
    end
  end
end
