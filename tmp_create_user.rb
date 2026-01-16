user = User.find_by(email: 'john@acme.inc')
if user
  puts "Usuario encontrado:"
  puts "Email: #{user.email}"
  puts "Nome: #{user.name}"
else
  puts "Usuario nao encontrado. Criando..."
  AccountBuilder.new(
    account_name: 'Acme Inc',
    email: 'john@acme.inc',
    user_full_name: 'John',
    user_password: 'Password1!',
    super_admin: true,
    confirmed: true
  ).perform
  puts "Usuario criado com sucesso!"
end
