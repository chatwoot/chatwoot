user = User.find_or_initialize_by(email: 'admin@defender.com')
user.password = 'Admin@123456'
user.password_confirmation = 'Admin@123456'
user.name = 'Admin'
user.confirmed_at = Time.now
user.save!

account = Account.find_or_create_by!(name: 'Admin')

account_user = AccountUser.find_or_initialize_by(account: account, user: user)
account_user.role = :administrator
account_user.save!

puts '================================'
puts 'Super admin criado com sucesso!'
puts 'Email: admin@defender.com'
puts 'Senha: Admin@123456'
puts '================================'
