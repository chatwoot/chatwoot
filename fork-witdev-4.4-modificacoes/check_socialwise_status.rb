#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== VERIFICAÇÃO RÁPIDA DO SOCIALWISE ==="
puts ""

# Verificar todas as contas
Account.all.each do |account|
  puts "CONTA: #{account.name} (ID: #{account.id})"
  
  # Verificar hook do Socialwise
  hook = account.hooks.find_by(app_id: 'socialwise_chatwit')
  if hook
    puts "  ✅ Hook encontrado:"
    puts "    - Status: #{hook.status}"
    puts "    - Settings: #{hook.settings.inspect}"
    
    # Testar métodos do serviço
    service = Integrations::Socialwise::WebhookEnhancerService
    puts "    - socialwise_active?: #{service.socialwise_active?(account)}"
    puts "    - webhook_enhancement_enabled?: #{service.webhook_enhancement_enabled?(account)}"
  else
    puts "  ❌ Hook NÃO encontrado"
  end
  
  # Verificar inboxes WhatsApp da conta
  whatsapp_inboxes = account.inboxes.joins(:channel).where(channel_type: 'Channel::Whatsapp')
  puts "  📥 Inboxes WhatsApp: #{whatsapp_inboxes.count}"
  whatsapp_inboxes.each do |inbox|
    puts "    - #{inbox.name} (#{inbox.channel.phone_number})"
    puts "      API Key: #{inbox.channel.provider_config['api_key'].present? ? 'Presente' : 'Ausente'}"
    puts "      Phone Number ID: #{inbox.channel.provider_config['phone_number_id'] || 'Ausente'}"
  end
  
  puts ""
end

puts "=== RESUMO ==="
total_accounts = Account.count
socialwise_accounts = Account.joins(:hooks).where(hooks: { app_id: 'socialwise_chatwit', status: 'enabled' }).count
puts "Total de contas: #{total_accounts}"
puts "Contas com Socialwise ativo: #{socialwise_accounts}"
puts ""

if socialwise_accounts == 0
  puts "🚨 PROBLEMA: Nenhuma conta tem o Socialwise ativo!"
  puts "   Isso explica por que os dados estão nulos."
  puts ""
  puts "SOLUÇÃO:"
  puts "1. Acesse o dashboard de integrações"
  puts "2. Ative o Socialwise Chatwit"
  puts "3. Configure as opções desejadas"
end