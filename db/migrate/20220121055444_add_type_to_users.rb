class AddTypeToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :type, :string
    migrate_existing_super_admins

    drop_table :super_admins do |t|
      t.string :email,              null: false, default: ''
      t.string :encrypted_password, null: false, default: ''
      t.datetime :remember_created_at
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet     :current_sign_in_ip
      t.inet     :last_sign_in_ip
      t.timestamps null: false
    end
  end

  private

  def old_super_admins
    ActiveRecord::Base.connection.execute('SELECT * from super_admins').to_a
  end

  def create_user_account_for_super_admin(super_admin)
    u = User.new(email: super_admin['email'], name: "SuperUser #{super_admin['id']}", encrypted_password: super_admin['encrypted_password'],
                 confirmed_at: DateTime.now, type: 'SuperAdmin')
    u.save(validate: false)
  end

  def migrate_existing_super_admins
    old_super_admins.each do |super_admin|
      user = User.find_by(email: super_admin['email'])
      if user.present?
        user.update(type: 'SuperAdmin')
      else
        Rails.logger.debug { "User with email #{super_admin['email']} not found" }
        create_user_account_for_super_admin(super_admin)
      end
    end
  end
end
