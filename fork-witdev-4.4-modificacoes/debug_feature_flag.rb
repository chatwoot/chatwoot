#!/usr/bin/env ruby
# Script para debugar e forçar atualização da feature flag

account_id = 3

puts "🔍 DEBUGANDO FEATURE FLAG SOCIALWISE_RICH_DASHBOARD"
puts "=" * 60

# 1. Verificar no banco de dados
puts "\n1. 📊 VERIFICANDO NO BANCO DE DADOS:"
account_flag = AccountFeatureFlag.find_by(account_id: account_id, flag_name: 'SOCIALWISE_RICH_DASHBOARD')
if account_flag
  puts "   ✅ Flag específica da conta encontrada:"
  puts "   - ID: #{account_flag.id}"
  puts "   - Enabled: #{account_flag.enabled}"
  puts "   - Created: #{account_flag.created_at}"
  puts "   - Updated: #{account_flag.updated_at}"
else
  puts "   ❌ Nenhuma flag específica encontrada para a conta #{account_id}"
end

# 2. Verificar configuração global
puts "\n2. 🌍 VERIFICANDO CONFIGURAÇÃO GLOBAL:"
global_config = InstallationConfig.find_by(name: 'SOCIALWISE_RICH_DASHBOARD')
if global_config
  puts "   ✅ Configuração global encontrada:"
  puts "   - Value: #{global_config.value}"
  puts "   - Locked: #{global_config.locked}"
  puts "   - Updated: #{global_config.updated_at}"
else
  puts "   ❌ Nenhuma configuração global encontrada"
end

# 3. Verificar via Feature.get (como o código usa)
puts "\n3. 🔧 VERIFICANDO VIA Feature.get:"
enabled = Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id)
puts "   Resultado: #{enabled ? '✅ HABILITADA' : '❌ DESABILITADA'}"

# 4. Verificar cache
puts "\n4. 💾 VERIFICANDO CACHE:"
cache_key = "account_features_#{account_id}"
cached_features = Rails.cache.read(cache_key)
if cached_features
  puts "   ✅ Cache encontrado:"
  puts "   - SOCIALWISE_RICH_DASHBOARD: #{cached_features['SOCIALWISE_RICH_DASHBOARD']}"
  puts "   - Limpando cache..."
  Rails.cache.delete(cache_key)
  puts "   ✅ Cache limpo"
else
  puts "   ❌ Nenhum cache encontrado"
end

# 5. Forçar habilitação se necessário
puts "\n5. 🚀 FORÇANDO HABILITAÇÃO:"
if !enabled
  puts "   Flag está desabilitada, forçando habilitação..."
  Feature.set_account_flag(:SOCIALWISE_RICH_DASHBOARD, account_id, true)
  puts "   ✅ Flag habilitada via Feature.set_account_flag"
end

# 6. Verificação final
puts "\n6. ✅ VERIFICAÇÃO FINAL:"
final_enabled = Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id)
puts "   Status final: #{final_enabled ? '✅ HABILITADA' : '❌ DESABILITADA'}"

# 7. Limpar todos os caches relacionados
puts "\n7. 🧹 LIMPANDO CACHES:"
Rails.cache.delete_matched("account_features_*")
Rails.cache.delete_matched("installation_config_*")
Rails.cache.delete_matched("global_config_*")
puts "   ✅ Todos os caches relacionados foram limpos"

puts "\n" + "=" * 60
puts "🎯 PRÓXIMOS PASSOS:"
puts "1. Reinicie o servidor Rails se possível"
puts "2. Teste enviando uma nova mensagem 'Olá' para o bot"
puts "3. Verifique os logs para: 'Rich dashboard enabled check: true'"
puts "=" * 60