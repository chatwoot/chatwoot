#!/usr/bin/env ruby
# Script para sincronizar a feature flag entre o sistema do Administrate e o FeatureService

account_id = 3

puts "🔧 SINCRONIZANDO FEATURE FLAG SOCIALWISE_RICH_DASHBOARD"
puts "=" * 60

# 1. Verificar se a conta tem a feature habilitada via selected_feature_flags
puts "\n1. 📊 VERIFICANDO SELECTED_FEATURE_FLAGS DA CONTA:"
account = Account.find(account_id)
selected_features = account.selected_feature_flags || []
puts "   Selected features: #{selected_features.inspect}"

if selected_features.include?('SOCIALWISE_RICH_DASHBOARD')
  puts "   ✅ SOCIALWISE_RICH_DASHBOARD está nas selected_feature_flags"
  
  # 2. Sincronizar com AccountFeatureFlag
  puts "\n2. 🔄 SINCRONIZANDO COM AccountFeatureFlag:"
  account_flag = AccountFeatureFlag.find_or_initialize_by(
    account_id: account_id,
    flag_name: 'SOCIALWISE_RICH_DASHBOARD'
  )
  
  account_flag.enabled = true
  account_flag.save!
  
  puts "   ✅ AccountFeatureFlag criada/atualizada: enabled = #{account_flag.enabled}"
  
else
  puts "   ❌ SOCIALWISE_RICH_DASHBOARD NÃO está nas selected_feature_flags"
  puts "   🔧 Adicionando à lista..."
  
  # Adicionar à lista de features selecionadas
  updated_features = (selected_features + ['SOCIALWISE_RICH_DASHBOARD']).uniq
  account.update!(selected_feature_flags: updated_features)
  
  puts "   ✅ Adicionada às selected_feature_flags: #{updated_features.inspect}"
  
  # Criar AccountFeatureFlag
  account_flag = AccountFeatureFlag.find_or_create_by(
    account_id: account_id,
    flag_name: 'SOCIALWISE_RICH_DASHBOARD'
  )
  account_flag.update!(enabled: true)
  
  puts "   ✅ AccountFeatureFlag criada: enabled = #{account_flag.enabled}"
end

# 3. Limpar todos os caches
puts "\n3. 🧹 LIMPANDO CACHES:"
Feature.clear_cache
Rails.cache.delete_matched("feature_flag:*")
Rails.cache.delete_matched("account_features_*")
GlobalConfig.clear_cache

puts "   ✅ Todos os caches limpos"

# 4. Verificar via Feature.get
puts "\n4. ✅ VERIFICAÇÃO FINAL:"
enabled = Feature.get(:SOCIALWISE_RICH_DASHBOARD, account_id)
puts "   Feature.get(:SOCIALWISE_RICH_DASHBOARD, #{account_id}): #{enabled ? '✅ HABILITADA' : '❌ DESABILITADA'}"

# 5. Verificar via FeatureService diretamente
puts "\n5. 🔍 VERIFICAÇÃO DETALHADA:"
account_flag_value = FeatureService.send(:get_account_flag, 'SOCIALWISE_RICH_DASHBOARD', account_id)
global_flag_value = FeatureService.send(:get_global_flag, 'SOCIALWISE_RICH_DASHBOARD')

puts "   Account flag: #{account_flag_value.inspect}"
puts "   Global flag: #{global_flag_value.inspect}"
puts "   Final result: #{enabled ? '✅ HABILITADA' : '❌ DESABILITADA'}"

puts "\n" + "=" * 60
puts "🎯 PRÓXIMOS PASSOS:"
puts "1. Reinicie o servidor Rails: 'rails restart' ou reinicie o processo"
puts "2. Teste enviando 'Olá' para o bot"
puts "3. Verifique os logs para: 'Rich dashboard enabled check: true'"
puts "=" * 60