class CreateContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :contacts do |t|
      t.string :name
      t.string :email
      t.string :phone_number
      t.integer :channel_id
      t.integer :account_id

      t.timestamps
    end
  end
end
