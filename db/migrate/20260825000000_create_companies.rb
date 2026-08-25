class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :website
      t.text :description
      t.jsonb :custom_attributes, default: {}, null: false
      t.timestamps
    end
    add_index :companies, %i[account_id name]

    # contacts.company_id and its index already exist; only add the constraint.
    add_foreign_key :contacts, :companies, validate: false
  end
end
