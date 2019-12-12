class UpdateUserInviteForeignKey < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :users, column: :inviter_id
    add_foreign_key :users, :users, column: :inviter_id, on_delete: :nullify
  end
end
