#!/usr/bin/env ruby
# Corrige o problema da migração CreateCaptainTables quando tabelas já existem
#
# Uso: docker exec chatwit_container ruby fix-captain-migration.rb

puts "🔧 Corrigindo migração CreateCaptainTables..."

# Conectar ao Rails
require '/app/config/environment'

begin
  # Verificar se as tabelas já existem
  captain_assistants_exists = ActiveRecord::Base.connection.table_exists?(:captain_assistants)
  captain_documents_exists = ActiveRecord::Base.connection.table_exists?(:captain_documents)
  captain_responses_exists = ActiveRecord::Base.connection.table_exists?(:captain_assistant_responses)
  
  puts "📋 Status das tabelas:"
  puts "  - captain_assistants: #{captain_assistants_exists ? '✅ existe' : '❌ não existe'}"
  puts "  - captain_documents: #{captain_documents_exists ? '✅ existe' : '❌ não existe'}"
  puts "  - captain_assistant_responses: #{captain_responses_exists ? '✅ existe' : '❌ não existe'}"
  
  # Se pelo menos uma tabela existe, marcar a migração como executada
  if captain_assistants_exists || captain_documents_exists || captain_responses_exists
    puts ""
    puts "🔄 Marcando migração 20250104200055 como executada..."
    
    ActiveRecord::Base.connection.execute(
      "INSERT INTO schema_migrations (version) VALUES ('20250104200055') ON CONFLICT (version) DO NOTHING"
    )
    
    puts "✅ Migração marcada com sucesso!"
    puts ""
    puts "🎉 Agora você pode executar 'bundle exec rails db:migrate' normalmente"
  else
    puts ""
    puts "ℹ️  Nenhuma tabela Captain encontrada - migração normal pode prosseguir"
  end
  
rescue => e
  puts "❌ Erro: #{e.message}"
  exit 1
end 