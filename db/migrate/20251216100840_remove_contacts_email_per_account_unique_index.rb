class RemoveContactsEmailPerAccountUniqueIndex < ActiveRecord::Migration[7.1]
  def up
    remove_index :contacts, name: :uniq_email_per_account_contact
    add_index :contacts, %i[account_id email],
              name: :email_per_account_contact
  end

  def down
    remove_index :contacts, name: :email_per_account_contact
    add_index :contacts, %i[account_id email],
              unique: true,
              name: :uniq_email_per_account_contact
  end
end
