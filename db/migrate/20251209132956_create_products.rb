class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title_en, null: false
      t.string :title_ar
      t.text :description_en
      t.text :description_ar
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: 'SAR'
      t.timestamps
    end

    add_index :products, [:account_id, :title_en], unique: true
  end
end
