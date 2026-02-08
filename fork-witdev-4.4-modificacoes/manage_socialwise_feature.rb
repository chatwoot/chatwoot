#!/usr/bin/env ruby
# Script para gerenciar a feature SOCIALWISE_RICH_DASHBOARD

def show_account_features(account_id)
  account = Account.find(account_id)
  
  puts "=== CONTA #{account_id}: #{account.name} ==="
  puts "Feature flags (raw): #{account.feature_flags}"
  puts "Feature flags (binary): #{account.feature_flags.to_s(2).rjust(64, '0')}"
  puts ""
  
  # Verificar estado da SOCIALWISE_RICH_DASHBOARD
  if account.respond_to?('feature_SOCIALWISE_RICH_DASHBOARD?')
    enabled = account.feature_SOCIALWISE_RICH_DASHBOARD?
    puts "SOCIALWISE_RICH_DASHBOARD: #{enabled ? '✅ HABILITADA' : '❌ DESABILITADA'}"
  else
    puts "❌ Método feature_SOCIALWISE_RICH_DASHBOARD? não existe"
    puts "   Isso indica que o servidor precisa ser reiniciado após adicionar a feature"
  end
  
  puts ""
  
  # Mostrar todas as features habilitadas
  puts "Features habilitadas:"
  account.enabled_features.each do |name, enabled|
    puts "  #{name}: #{enabled ? '✅' : '❌'}"
  end
  
  account
end

def enable_feature(account, feature_name)
  puts "Habilitando #{feature_name}..."
  
  if account.respond_to?("feature_#{feature_name}=")
    account.send("feature_#{feature_name}=", true)
    account.save!
    puts "✅ Feature habilitada!"
  else
    puts "❌ Método feature_#{feature_name}= não existe"
    return false
  end
  
  true
end

def disable_feature(account, feature_name)
  puts "Desabilitando #{feature_name}..."
  
  if account.respond_to?("feature_#{feature_name}=")
    account.send("feature_#{feature_name}=", false)
    account.save!
    puts "✅ Feature desabilitada!"
  else
    puts "❌ Método feature_#{feature_name}= não existe"
    return false
  end
  
  true
end

def test_instagram_service(account)
  puts "\n=== TESTANDO INSTAGRAM RICH MESSAGE SERVICE ==="
  
  # Encontrar uma conversa Instagram
  conversation = account.conversations.joins(:inbox)
                        .where(inboxes: { channel_type: 'Channel::Instagram' })
                        .first
  
  if conversation
    puts "✅ Conversa Instagram encontrada: #{conversation.id}"
    
    # Criar mensagem de teste
    message = Message.new(
      conversation: conversation,
      account: account,
      inbox: conversation.inbox,
      content: 'Teste de mensagem rica',
      message_type: :outgoing
    )
    
    # Testar o serviço
    rich_payload = {
      'template_type' => 'generic',
      'elements' => [
        {
          'title' => 'Produto de Teste',
          'subtitle' => 'Testando o dashboard rico'
        }
      ]
    }
    
    service = Instagram::RichMessageService.new(message: message, rich_payload: rich_payload)
    enabled = service.send(:rich_dashboard_enabled?)
    
    puts "Resultado do serviço: #{enabled ? '✅ HABILITADO' : '❌ DESABILITADO'}"
    
    if enabled
      puts "✅ O serviço detectou a feature como habilitada!"
      puts "   As mensagens ricas serão processadas e espelhadas no dashboard."
    else
      puts "❌ O serviço detectou a feature como desabilitada."
      puts "   As mensagens ricas serão enviadas normalmente, mas não espelhadas."
    end
  else
    puts "⚠️  Nenhuma conversa Instagram encontrada para teste"
  end
end

# MENU PRINCIPAL
puts "=== GERENCIADOR DE FEATURES SOCIALWISE ==="
puts ""

# Verificar se a feature existe no sistema
feature_list = YAML.safe_load(Rails.root.join('config/features.yml').read)
socialwise_feature = feature_list.find { |f| f['name'] == 'SOCIALWISE_RICH_DASHBOARD' }

if socialwise_feature
  puts "✅ Feature SOCIALWISE_RICH_DASHBOARD encontrada no sistema"
  puts "   Display: #{socialwise_feature['display_name']}"
  puts "   Habilitada por padrão: #{socialwise_feature['enabled']}"
else
  puts "❌ Feature SOCIALWISE_RICH_DASHBOARD não encontrada no config/features.yml"
  exit 1
end

puts ""

# Verificar conta 3
begin
  account = show_account_features(3)
  
  # Menu de opções
  puts "\n=== OPÇÕES ==="
  puts "1. Habilitar SOCIALWISE_RICH_DASHBOARD"
  puts "2. Desabilitar SOCIALWISE_RICH_DASHBOARD"
  puts "3. Testar Instagram Rich Message Service"
  puts "4. Mostrar informações novamente"
  puts "5. Sair"
  
  print "\nEscolha uma opção (1-5): "
  
  # Para script não-interativo, vamos apenas mostrar as informações
  puts "1 (habilitando automaticamente)"
  
  # Verificar se já está habilitada
  if account.respond_to?('feature_SOCIALWISE_RICH_DASHBOARD?')
    if account.feature_SOCIALWISE_RICH_DASHBOARD?
      puts "✅ Feature já está habilitada!"
    else
      enable_feature(account, 'SOCIALWISE_RICH_DASHBOARD')
      account.reload
      show_account_features(3)
    end
  else
    puts "❌ Métodos da feature não existem. Reinicie o servidor após adicionar a feature."
  end
  
  # Testar o serviço
  test_instagram_service(account)
  
rescue ActiveRecord::RecordNotFound
  puts "❌ Conta 3 não encontrada"
rescue => e
  puts "❌ Erro: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n=== SCRIPT CONCLUÍDO ==="