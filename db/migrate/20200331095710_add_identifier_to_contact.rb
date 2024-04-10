class AddIdentifierToContact < ActiveRecord::Migration[6.0]
  def change
    add_column :contacts, :identifier, :string, index: true, default: nil
    add_index :contacts, ['identifier', :account_id], unique: true, name: 'uniq_identifier_per_account_contact'
    add_index :contacts, ['email', :account_id], unique: true, name: 'uniq_email_per_account_contact'
  end
end
