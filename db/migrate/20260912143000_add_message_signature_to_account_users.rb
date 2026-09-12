# frozen_string_literal: true

class AddMessageSignatureToAccountUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :account_users, :message_signature, :text

    execute <<-SQL.squish
      UPDATE account_users
      SET message_signature = users.message_signature
      FROM users
      WHERE account_users.user_id = users.id
        AND users.message_signature IS NOT NULL
        AND users.message_signature != ''
    SQL
  end

  def down
    remove_column :account_users, :message_signature
  end
end
