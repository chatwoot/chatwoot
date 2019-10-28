class TransferDeviseUserData < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :devise_user_id, :integer

    transfer_user_data('users', 'devise_users')
    add_devise_user_id_to_users
  end

  def down
    transfer_user_data('devise_users', 'users')

    remove_column :users, :devise_user_id
  end

  private

  def add_devise_user_id_to_users
    DeviseUser.all.each do |devise_user|
      matching_user = User.where(
        uid: devise_user.uid,
        provider: devise_user.provider,
        name: devise_user.name,
        email: devise_user.email,
      ).first

      devise_user.update_attributes!(user: matching_user)
    end
  end

  def transfer_user_data(origin_table, destination_table)
    ActiveRecord::Base.connection.execute(<<-SQL
      INSERT INTO #{destination_table} (
        provider,
        uid,
        encrypted_password,
        reset_password_token,
        reset_password_sent_at,
        remember_created_at,
        confirmation_token,
        confirmed_at,
        confirmation_sent_at,
        name,
        nickname,
        image,
        email,
        tokens,
        created_at,
        updated_at
      )
      SELECT provider,
        uid,
        encrypted_password,
        reset_password_token,
        reset_password_sent_at,
        remember_created_at,
        confirmation_token,
        confirmed_at,
        confirmation_sent_at,
        name,
        nickname,
        image,
        email,
        tokens,
        created_at,
        updated_at
      FROM #{origin_table}
    SQL
    )
  end
end
