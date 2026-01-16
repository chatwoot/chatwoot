user = User.find_by(email: 'john@acme.inc')

if user
  puts "Usuario encontrado: #{user.email}"
  puts "Tipo: #{user.type}"
  puts "Confirmado: #{user.confirmed?}"
  puts "Senha definida: #{user.encrypted_password.present?}"
  
  # Resetar senha se necessário
  if user.encrypted_password.blank?
    puts "Definindo senha..."
    user.password = 'Password1!'
    user.password_confirmation = 'Password1!'
    user.save!
    puts "Senha definida!"
  end
  
  # Garantir que está confirmado
  unless user.confirmed?
    user.confirm
    puts "Usuario confirmado!"
  end
else
  puts "Usuario nao existe. Criando..."
  
  # Criar usuário diretamente
  user = User.new(
    name: 'John',
    email: 'john@acme.inc',
    password: 'Password1!',
    password_confirmation: 'Password1!',
    type: 'SuperAdmin'
  )
  user.skip_confirmation!
  
  if user.save!
    puts "Usuario criado com sucesso!"
    
    # Criar ou encontrar uma conta e associar
    account = Account.first || Account.create!(name: 'Acme Inc')
    
    unless AccountUser.exists?(account_id: account.id, user_id: user.id)
      AccountUser.create!(
        account_id: account.id,
        user_id: user.id,
        role: :administrator
      )
      puts "Usuario associado à conta!"
    end
  else
    puts "Erro ao criar usuario: #{user.errors.full_messages.join(', ')}"
  end
end

puts "Verificacao final:"
puts "  Email: #{user.email}"
puts "  Confirmado: #{user.confirmed?}"
puts "  Senha presente: #{user.encrypted_password.present?}"
