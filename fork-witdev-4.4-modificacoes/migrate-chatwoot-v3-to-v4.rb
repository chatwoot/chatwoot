#!/usr/bin/env ruby
# Script de Migração Segura: Chatwoot v3 -> v4
# Autor: Assistente IA
# Data: 2025-01-28
#
# Este script aplica as correções necessárias para migrar um backup
# do Chatwoot v3 restaurado em um ambiente Chatwoot v4
#
# USO:
#   bundle exec rails runner migrate-chatwoot-v3-to-v4.rb

puts "========================================"
puts "  MIGRAÇÃO SEGURA CHATWOOT v3 -> v4"
puts "========================================"
puts

# Verificar se estamos em produção
if Rails.env.production?
  puts "🔥 AMBIENTE DE PRODUÇÃO DETECTADO"
  puts "⚠️  Este script fará alterações no banco de dados!"
  puts
  
  # Em produção, pedir confirmação
  print "Deseja continuar? (digite 'SIM' para confirmar): "
  confirmation = gets.chomp
  unless confirmation == 'SIM'
    puts "❌ Operação cancelada pelo usuário."
    exit 1
  end
else
  puts "🔧 Ambiente: #{Rails.env}"
end

puts
puts "1️⃣ Verificando estrutura do banco..."

# Verificar se as colunas necessárias existem
begin
  # Testar se Account.settings funciona
  Account.connection.schema_cache.clear!
  Account.reset_column_information
  
  if Account.column_names.include?('settings')
    puts "✅ Coluna 'settings' já existe na tabela accounts"
  else
    puts "➕ Adicionando coluna 'settings' à tabela accounts..."
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE accounts ADD COLUMN settings jsonb DEFAULT '{}'"
    )
    puts "✅ Coluna 'settings' adicionada com sucesso"
  end

  # Verificar Inbox.csat_config
  Inbox.connection.schema_cache.clear!
  Inbox.reset_column_information
  
  if Inbox.column_names.include?('csat_config')
    puts "✅ Coluna 'csat_config' já existe na tabela inboxes"
  else
    puts "➕ Adicionando coluna 'csat_config' à tabela inboxes..."
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE inboxes ADD COLUMN csat_config jsonb DEFAULT '{}' NOT NULL"
    )
    puts "✅ Coluna 'csat_config' adicionada com sucesso"
  end

rescue => e
  puts "❌ Erro ao verificar/adicionar colunas: #{e.message}"
  exit 1
end

puts
puts "2️⃣ Marcando migrações manuais como executadas..."

# Marcar as migrações que aplicamos manualmente
manual_migrations = [
  '20250421082927', # add_settings_column_to_account
  '20250514045638'  # add_csat_config_to_inboxes (se existir)
]

manual_migrations.each do |version|
  begin
    ActiveRecord::Base.connection.execute(
      "INSERT INTO schema_migrations (version) VALUES ('#{version}') ON CONFLICT (version) DO NOTHING"
    )
    puts "✅ Migração #{version} marcada como executada"
  rescue => e
    puts "⚠️  Erro ao marcar migração #{version}: #{e.message}"
  end
end

puts
puts "3️⃣ Verificando migrações pendentes..."

# Verificar quantas migrações estão pendentes
pending_migrations = ActiveRecord::Base.connection.migration_context.migrations_status.select { |status, _, _| status == "down" }

if pending_migrations.any?
  puts "📋 Encontradas #{pending_migrations.count} migrações pendentes"
  puts
  puts "4️⃣ Executando migrações pendentes..."
  
  begin
    ActiveRecord::Tasks::DatabaseTasks.migrate
    puts "✅ Todas as migrações foram executadas com sucesso!"
  rescue => e
    puts "❌ Erro durante as migrações: #{e.message}"
    puts "🔍 Verifique os logs para mais detalhes"
    exit 1
  end
else
  puts "✅ Nenhuma migração pendente encontrada"
end

puts
puts "5️⃣ Testando funcionalidades..."

begin
  # Testar Account.settings
  test_account = Account.first
  if test_account
    settings = test_account.settings
    puts "✅ Account.settings funciona: #{settings}"
  else
    puts "⚠️  Nenhuma conta encontrada para teste"
  end

  # Testar Inbox.csat_config
  test_inbox = Inbox.first
  if test_inbox
    csat_config = test_inbox.csat_config
    puts "✅ Inbox.csat_config funciona: #{csat_config}"
  else
    puts "⚠️  Nenhum inbox encontrado para teste"
  end

  # Mostrar estatísticas
  puts
  puts "📊 Estatísticas do banco:"
  puts "   Contas: #{Account.count}"
  puts "   Usuários: #{User.count}"
  puts "   Inboxes: #{Inbox.count}"
  puts "   Mensagens: #{Message.count}"

rescue => e
  puts "❌ Erro durante os testes: #{e.message}"
  exit 1
end

puts
puts "========================================"
puts "✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!"
puts "========================================"
puts
puts "🎉 Seu Chatwoot v3 foi migrado para v4!"
puts "🔧 Reinicie a aplicação para aplicar todas as mudanças"
puts
puts "📋 Próximos passos:"
puts "1. Reiniciar containers/serviços"
puts "2. Verificar logs da aplicação"
puts "3. Testar funcionalidades no navegador"
puts 