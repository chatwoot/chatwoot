class CreateAccountAddresses < ActiveRecord::Migration[7.0]
  def change
    create_table :account_addresses do |t|
      t.references :account, null: false, foreign_key: true
      t.string :street, null: false
      t.string :exterior_number, null: false
      t.string :interior_number
      t.string :neighborhood, null: false
      t.string :postal_code, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :email
      t.string :phone
      t.string :webpage
      t.text :establishment_summary
      t.timestamps
    end
  end
end
