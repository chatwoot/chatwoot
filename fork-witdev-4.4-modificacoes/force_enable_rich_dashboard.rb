#!/usr/bin/env ruby
# Script para forçar a habilitação da SOCIALWISE_RICH_DASHBOARD para conta 3

puts "=== FORÇANDO HABILITAÇÃO DA SOCIALWISE_RICH_DASHBOARD ==="

begin
  # Encontrar a conta 3
  account = Account.find(3)
  puts "✅ Conta encontrada: #{account.name} (ID: #{account.id})"
  
  # Verificar estado atual
  puts "\nEstado atual:"
  puts "  Feature flags (raw): #{account.feature_flags}"
  
  begin
    current_state = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
    puts "  SOCIALWISE_RICH_DASHBOARD: #{current_state}"
  rescue => e
    puts "  ❌ Erro ao verificar estado atual: #{e.message}"
  end
  
  # Habilitar a feature
  puts "\nHabilitando feature..."
  
  begin
    # Método 1: Usando enable_features!
    account.enable_features!('SOCIALWISE_RICH_DASHBOARD')
    puts "✅ Feature habilitada usando enable_features!"
  rescue => e
    puts "❌ Erro com enable_features!: #{e.message}"
    
    # Método 2: Usando o método direto
    begin
      account.send("feature_SOCIALWISE_RICH_DASHBOARD=", true)
      account.save!
      puts "✅ Feature habilitada usando método direto"
    rescue => e2
      puts "❌ Erro com método direto: #{e2.message}"
      
      # Método 3: Manipulação direta dos bits
      puts "Tentando manipulação direta dos bits..."
      
      # Encontrar a posição da feature
      features = Featurable::FEATURES
      feature_position = nil
      features.each do |pos, feature_name|
        if feature_name.to_s == 'feature_SOCIALWISE_RICH_DASHBOARD'
          feature_position = pos
          break
        end
      end
      
      if feature_position
        puts "Feature encontrada na posição: #{feature_position}"
        current_flags = account.feature_flags || 0
        new_flags = current_flags | (1 << (feature_position - 1))
        
        account.update_column(:feature_flags, new_flags)
        puts "✅ Feature habilitada via manipulação de bits"
      else
        puts "❌ Posição da feature não encontrada"
      end
    end
  end
  
  # Verificar estado final
  puts "\nEstado final:"
  account.reload
  puts "  Feature flags (raw): #{account.feature_flags}"
  puts "  Feature flags (binary): #{account.feature_flags.to_s(2)}"
  
  begin
    final_state = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
    puts "  SOCIALWISE_RICH_DASHBOARD: #{final_state}"
    
    if final_state
      puts "✅ SUCCESS: Feature está habilitada!"
    else
      puts "❌ FAILED: Feature ainda está desabilitada"
    end
  rescue => e
    puts "❌ Erro ao verificar estado final: #{e.message}"
  end
  
  # Testar com o Instagram Rich Message Service
  puts "\nTestando com Instagram Rich Message Service..."
  
  conversation = account.conversations.joins(:inbox)
                        .where(inboxes: { channel_type: 'Channel::Instagram' })
                        .first
  
  if conversation
    message = Message.new(
      conversation: conversation,
      account: account,
      inbox: conversation.inbox,
      content: 'Teste',
      message_type: :outgoing
    )
    
    rich_payload = { 'template_type' => 'generic', 'elements' => [{ 'title' => 'Teste' }] }
    service = Instagram::RichMessageService.new(message: message, rich_payload: rich_payload)
    
    enabled = service.send(:rich_dashboard_enabled?)
    puts "Instagram Rich Message Service result: #{enabled}"
    
    if enabled
      puts "✅ Serviço detectou feature como habilitada!"
    else
      puts "❌ Serviço ainda detecta feature como desabilitada"
    end
  else
    puts "⚠️  Nenhuma conversa Instagram encontrada para teste"
  end
  
rescue ActiveRecord::RecordNotFound
  puts "❌ Conta 3 não encontrada"
rescue => e
  puts "❌ Erro geral: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n=== SCRIPT CONCLUÍDO ==="