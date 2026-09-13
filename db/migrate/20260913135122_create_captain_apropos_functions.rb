class CreateCaptainAproposFunctions < ActiveRecord::Migration[7.2]
  def change
    create_table :captain_apropos_functions do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id, null: false
      t.string :name, null: false
      t.string :description, null: false
      t.jsonb :definition, null: false
      t.timestamps
    end
    add_index :captain_apropos_functions, [:account_id, :user_id, :name], unique: true
  end
end
