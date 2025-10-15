class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :domain
      t.text :description
      t.references :account, null: false

      t.timestamps
    end
    add_index :companies, [:name, :account_id]
    add_index :companies, [:domain, :account_id]
  end
end
