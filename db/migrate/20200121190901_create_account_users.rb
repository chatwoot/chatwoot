class CreateAccountUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :account_users do |t|
      t.references :account, foreign_key: true, index: true
      t.references :user, foreign_key: true, index: true

      t.integer :role, default: 0
      t.bigint :inviter_id

      t.timestamps
    end

    ::User.all.each do |user|
      account_user = ::AccountUser.create!(
        account_id: user.account_id,
        user_id: user.id,
        role: user.role,
        inviter_id: user.inviter_id
      )
    end

    remove_column :users, :account_id, :bigint
    remove_column :users, :role, :integer
    remove_column :users, :inviter_id, :bigint
  end
end
