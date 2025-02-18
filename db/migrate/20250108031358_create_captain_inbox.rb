class CreateCaptainInbox < ActiveRecord::Migration[7.0]
  def change
    create_table :captain_inboxes do |t|
      t.references :captain_assistant, null: false
      t.references :inbox, null: false
      t.timestamps
    end

    add_index :captain_inboxes, [:captain_assistant_id, :inbox_id], unique: true
  end
end
