class CreatePriorityGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :priority_groups do |t|
      t.string :name, null: false
      t.references :account, null: false, foreign_key: true 

      t.timestamps
    end

    add_index :priority_groups, [:account_id, :name], unique: true
  end
end
