class AddDomainToAccounts < ActiveRecord::Migration[6.0]
  def change
    change_table :accounts, bulk: true do |t|
      t.string :domain, limit: 100
      t.string :support_email, limit: 100
      t.integer :settings_flags, default: 0, null: false
    end
  end
end
