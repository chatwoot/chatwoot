class CreateDepartments < ActiveRecord::Migration[7.0]
  def change
    create_table :departments do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :department_type, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :departments, [:name, :account_id], unique: true
    add_index :departments, :account_id
  end
end