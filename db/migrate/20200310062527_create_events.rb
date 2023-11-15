class CreateEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.string :name
      t.float :value
      t.integer :account_id
      t.integer :inbox_id
      t.integer :user_id
      t.integer :conversation_id

      t.timestamps
    end
  end
end
