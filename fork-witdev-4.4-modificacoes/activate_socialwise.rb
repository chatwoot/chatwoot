#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== ATIVAÇÃO AUTOMÁTICA DO SOCIALWISE ==="
puts ""

# Pedir confirmação
print "Deseja ativar o Socialwise para todas as contas? (y/N): "
response = gets.chomp.downcase

unless response == 'y' || response == 'yes'
  puts "Operação cancelada."
  exit
end

Account.all.each do |account|
  puts "Processando conta: #{account.name} (ID: #{account.id})"
  
  # Verificar se já existe hook
  hook = account.hooks.find_by(app_id: 'socialwise_chatwit')
  
  if hook
    puts "  ✅ Hook já existe (Status: #{hook.status})"
    
    # Atualizar settings se necessário
    if hook.status != 'enabled' || hook.settings.dig('enabled') != true
      hook.update!(
        status: 'enabled',
        settings: {
          'enabled' => true,
          'webhook_enhancement_enabled' => true
        }
      )
      puts "  🔄 Hook atualizado para ativo"
    else
      puts "  ✅ Hook já está ativo"
    end
  else
    # Criar novo hook
    hook = account.hooks.create!(
      app_id: 'socialwise_chatwit',
      status: 'enabled',
      settings: {
        'enabled' => true,
        'webhook_enhancement_enabled' => true
      }
    )
    puts "  ✨ Hook criado e ativado"
  end
  
  # Verificar resultado
  service = Integrations::Socialwise::WebhookEnhancerService
  active = service.socialwise_active?(account)
  webhook_enabled = service.webhook_enhancement_enabled?(account)
  
  puts "  📊 Status final:"
  puts "    - Socialwise ativo: #{active}"
  puts "    - Webhook enhancement: #{webhook_enabled}"
  puts ""
end

puts "=== ATIVAÇÃO CONCLUÍDA ==="
puts ""
puts "Agora teste enviando uma mensagem no WhatsApp para ver se os logs aparecem."