class CreateInboxMembers < ActiveRecord::Migration[5.0]
  def change
    create_table :inbox_members do |t|
      t.integer :user_id
      t.integer :inbox_id

      t.timestamps
    end
  end
end
