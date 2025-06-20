class CreateApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :applications do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.text :description
      t.string :status, default: 'active'
      t.datetime :last_used_at
      t.references :account, null: false, foreign_key: true
      t.timestamps
    end

    add_index :applications, [:account_id, :name], unique: true
    add_index :applications, :status
  end
end
