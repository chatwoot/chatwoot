class AddTypeToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :type, :string
    migrate_existing_super_admins
    drop_table :super_admins
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
