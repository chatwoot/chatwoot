class AddUniquenessConstraintToAccountUsers < ActiveRecord::Migration[6.0]
  def change
    add_index :account_users, [:account_id, :user_id], unique: true, name: 'uniq_user_id_per_account_id'
  end
end
