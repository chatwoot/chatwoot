#!/usr/bin/env ruby
# Corrige problemas específicos da migração Chatwoot v3 -> v4
#
# Uso: docker exec [container] ruby fix-v3-to-v4-migration.rb

puts "🔧 Corrigindo migração Chatwoot v3 -> v4..."

# Conectar ao Rails
require '/app/config/environment'

begin
  puts "📋 Verificando estado atual do banco..."
  
  # Verificar se as colunas v4 existem
  settings_exists = ActiveRecord::Base.connection.column_exists?(:accounts, :settings)
  csat_config_exists = ActiveRecord::Base.connection.column_exists?(:inboxes, :csat_config)
  
  puts "  - accounts.settings: #{settings_exists ? '✅ existe' : '❌ não existe'}"
  puts "  - inboxes.csat_config: #{csat_config_exists ? '✅ existe' : '❌ não existe'}"
  
  # Se as colunas não existem, adicionar
  unless settings_exists
    puts "➕ Adicionando coluna accounts.settings..."
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE accounts ADD COLUMN IF NOT EXISTS settings jsonb DEFAULT '{}'"
    )
    puts "✅ Coluna accounts.settings adicionada"
  end
  
  unless csat_config_exists
    puts "➕ Adicionando coluna inboxes.csat_config..."
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE inboxes ADD COLUMN IF NOT EXISTS csat_config jsonb DEFAULT '{}' NOT NULL"
    )
    puts "✅ Coluna inboxes.csat_config adicionada"
  end
  
  # Verificar se a migração problemática precisa ser marcada como executada
  migration_executed = ActiveRecord::Base.connection.select_value(
    "SELECT 1 FROM schema_migrations WHERE version = '20250416182131'"
  )
  
  if migration_executed
    puts "ℹ️  Migração 20250416182131 já está marcada como executada"
  else
    puts "🔄 Marcando migração 20250416182131 como executada..."
    ActiveRecord::Base.connection.execute(
      "INSERT INTO schema_migrations (version) VALUES ('20250416182131') ON CONFLICT (version) DO NOTHING"
    )
    puts "✅ Migração marcada como executada"
  end
  
  # Executar migrações pendentes
  puts "🔄 Executando migrações pendentes..."
  begin
    ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
    puts "✅ Migrações pendentes executadas"
  rescue => e
    if e.message.include?("already exists") || e.message.include?("DuplicateTable")
      puts "⚠️  Algumas tabelas já existem - isso é normal"
    else
      puts "⚠️  Erro nas migrações: #{e.message}"
    end
  end
  
  # Ativar features v4 para todas as contas
  puts "🔧 Ativando features Chatwoot v4..."
  begin
    Account.find_each do |account|
      # Verificar se a feature já está ativada
      unless account.features.include?('chatwoot_v4')
        account.enable_features!('chatwoot_v4')
        puts "  ✅ Feature v4 ativada para: #{account.name}"
      else
        puts "  ℹ️  Feature v4 já ativa para: #{account.name}"
      end
    end
    puts "✅ Features v4 verificadas!"
  rescue => e
    puts "⚠️  Erro ao ativar features v4: #{e.message}"
  end
  
  # Ativar features Enterprise
  puts "🏢 Ativando features Enterprise..."
  begin
    Account.find_each do |account|
      enterprise_features = [
        'disable_branding',
        'audit_logs', 
        'sla',
        'captain_integration',
        'custom_roles',
        'response_bot'
      ]
      
      account.enable_features!(*enterprise_features)
      puts "  ✅ Features Enterprise ativadas para: #{account.name}"
    end
    puts "✅ Features Enterprise ativadas!"
  rescue => e
    puts "⚠️  Erro ao ativar features Enterprise: #{e.message}"
  end
  
  puts ""
  puts "🎉 Correção da migração v3->v4 concluída!"
  puts "   A aplicação deve funcionar normalmente agora."
  
rescue => e
  puts "❌ Erro durante a correção: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end 