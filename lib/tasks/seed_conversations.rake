namespace :db do
  desc "Seed conversations for testing date filters"
  task seed_conversations: :environment do
    puts "🌱 Sembrando conversaciones de ejemplo..."
    
    # Obtener la cuenta y usuario existentes
    account = Account.first
    user = User.first
    
    if account.nil? || user.nil?
      puts "❌ Error: No se encontraron cuentas o usuarios. Ejecuta 'rails db:seed' primero."
      exit 1
    end
    
    # Obtener el inbox existente
    inbox = account.inboxes.first
    
    if inbox.nil?
      puts "❌ Error: No se encontró un inbox. Ejecuta 'rails db:seed' primero."
      exit 1
    end
    
    puts "📧 Usando cuenta: #{account.name}"
    puts "👤 Usando usuario: #{user.name}"
    puts "📥 Usando inbox: #{inbox.name}"
    
    # Crear conversaciones de ejemplo
    conversations = Seeders::ConversationSeeder.create_sample_conversations(account, inbox, user)
    
    puts "✅ ¡Listo! Se crearon #{conversations.count} conversaciones con diferentes fechas:"
    puts "   - 30 conversaciones de los últimos 30 días"
    puts "   - 7 conversaciones de la última semana"
    puts "   - 5 conversaciones de hoy"
    puts ""
    puts "Ahora puedes probar filtros por fecha en:"
    puts "http://localhost:3000"
  end
end
