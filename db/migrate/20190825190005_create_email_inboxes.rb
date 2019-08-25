class CreateEmailInboxes < ActiveRecord::Migration[6.1]
  def change
    create_table :email_inboxes do |t|
      t.string "avatar"
      t.string :email, :null => false
      t.references :account
      t.timestamps
    end
    add_index :email_inboxes, :email
  end
end
