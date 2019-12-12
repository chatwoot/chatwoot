class AddInvitedByToUser < ActiveRecord::Migration[6.0]
  def change
    add_reference(:users, :inviter, foreign_key: { to_table: :users })
  end
end
