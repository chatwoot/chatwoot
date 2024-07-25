class CreateAccountProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :account_products do |t|
      t.references :account, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
