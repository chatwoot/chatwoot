#!/usr/bin/env ruby
# Script para explicar como funciona o sistema de features do Chatwoot

puts "=== COMO FUNCIONA O SISTEMA DE FEATURES DO CHATWOOT ==="
puts ""

# 1. Explicar a estrutura
puts "1. ESTRUTURA DO SISTEMA:"
puts "   • Features são definidas em config/features.yml"
puts "   • Cada conta tem uma coluna 'feature_flags' (integer) que armazena bits"
puts "   • Cada feature ocupa 1 bit na posição correspondente"
puts "   • O módulo Featurable gera métodos dinâmicos para cada feature"
puts ""

# 2. Mostrar as features disponíveis
puts "2. FEATURES DISPONÍVEIS NO SISTEMA:"
feature_list = YAML.safe_load(Rails.root.join('config/features.yml').read)
feature_list.each_with_index do |feature, index|
  status = feature['enabled'] ? '✅' : '❌'
  puts "   #{index + 1:2d}. #{feature['name'].ljust(30)} #{status} #{feature['display_name']}"
end
puts ""

# 3. Explicar como verificar
puts "3. COMO VERIFICAR SE UMA FEATURE ESTÁ HABILITADA:"
puts "   account = Account.find(3)"
puts "   account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')"
puts "   # ou"
puts "   account.feature_SOCIALWISE_RICH_DASHBOARD?"
puts ""

# 4. Explicar como habilitar/desabilitar
puts "4. COMO HABILITAR/DESABILITAR:"
puts "   # Habilitar"
puts "   account.feature_SOCIALWISE_RICH_DASHBOARD = true"
puts "   account.save!"
puts ""
puts "   # Desabilitar"
puts "   account.feature_SOCIALWISE_RICH_DASHBOARD = false"
puts "   account.save!"
puts ""
puts "   # Ou usando métodos helper"
puts "   account.enable_features!('SOCIALWISE_RICH_DASHBOARD')"
puts "   account.disable_features!('SOCIALWISE_RICH_DASHBOARD')"
puts ""

# 5. Mostrar exemplo prático com conta 3
puts "5. EXEMPLO PRÁTICO COM CONTA 3:"
begin
  account = Account.find(3)
  puts "   ✅ Conta encontrada: #{account.name}"
  puts "   Feature flags (raw): #{account.feature_flags}"
  puts "   Feature flags (binary): #{account.feature_flags.to_s(2).rjust(32, '0')}"
  puts ""
  
  # Verificar se os métodos existem
  if account.respond_to?('feature_SOCIALWISE_RICH_DASHBOARD?')
    current_state = account.feature_SOCIALWISE_RICH_DASHBOARD?
    puts "   SOCIALWISE_RICH_DASHBOARD atual: #{current_state ? '✅ HABILITADA' : '❌ DESABILITADA'}"
    
    # Mostrar como alterar
    puts ""
    puts "   Para alterar via console:"
    if current_state
      puts "   account.feature_SOCIALWISE_RICH_DASHBOARD = false  # desabilitar"
    else
      puts "   account.feature_SOCIALWISE_RICH_DASHBOARD = true   # habilitar"
    end
    puts "   account.save!"
    
  else
    puts "   ❌ Métodos da feature não existem ainda"
    puts "   Isso acontece quando:"
    puts "   • A feature foi adicionada ao config/features.yml mas o servidor não foi reiniciado"
    puts "   • O cache do Rails não foi limpo"
    puts ""
    puts "   SOLUÇÃO: Reinicie o servidor Rails"
  end
  
rescue ActiveRecord::RecordNotFound
  puts "   ❌ Conta 3 não encontrada"
end

puts ""

# 6. Explicar o painel do super admin
puts "6. PAINEL DO SUPER ADMIN:"
puts "   • Acesse /super_admin/accounts/3/edit"
puts "   • Procure por checkboxes que começam com 'feature_'"
puts "   • Marque/desmarque 'feature_SOCIALWISE_RICH_DASHBOARD'"
puts "   • Clique em 'Update Account'"
puts ""

# 7. Explicar como funciona no código
puts "7. COMO FUNCIONA NO CÓDIGO:"
puts "   O Instagram Rich Message Service verifica assim:"
puts "   "
puts "   def rich_dashboard_enabled?"
puts "     account = message.conversation.account"
puts "     enabled = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')"
puts "     Rails.logger.info \"Rich dashboard: \#{enabled} for account \#{account.id}\""
puts "     enabled"
puts "   end"
puts ""

# 8. Troubleshooting
puts "8. TROUBLESHOOTING:"
puts "   Se a feature não funciona:"
puts "   • Verifique se está no config/features.yml"
puts "   • Reinicie o servidor Rails"
puts "   • Verifique se os métodos existem: account.methods.grep(/SOCIALWISE/)"
puts "   • Verifique o valor dos bits: account.feature_flags"
puts "   • Teste no console: account.feature_SOCIALWISE_RICH_DASHBOARD?"
puts ""

puts "=== RESUMO ==="
puts "✅ Features são controladas por bits na coluna feature_flags"
puts "✅ Cada conta pode ter features habilitadas/desabilitadas individualmente"
puts "✅ O painel do super admin permite alterar via interface"
puts "✅ O console Rails permite alterar via código"
puts "✅ Mudanças são imediatas (não precisam de deploy)"
puts ""

puts "Para habilitar SOCIALWISE_RICH_DASHBOARD para conta 3:"
puts "rails console"
puts "account = Account.find(3)"
puts "account.feature_SOCIALWISE_RICH_DASHBOARD = true"
puts "account.save!"
puts ""

puts "=== FIM DA EXPLICAÇÃO ==="