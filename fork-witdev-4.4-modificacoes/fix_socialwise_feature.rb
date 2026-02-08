#!/usr/bin/env ruby
# Script simples para corrigir a feature SOCIALWISE_RICH_DASHBOARD

puts "=== CORREÇÃO SOCIALWISE_RICH_DASHBOARD ==="

# Verificar se a feature existe no sistema
puts "1. Verificando se a feature existe no sistema..."

# Recarregar as features
load Rails.root.join('app/models/concerns/featurable.rb')

# Verificar se a feature está na lista
feature_list = Featurable::FEATURE_LIST
socialwise_feature = feature_list.find { |f| f['name'] == 'SOCIALWISE_RICH_DASHBOARD' }

if socialwise_feature
  puts "✅ Feature encontrada: #{socialwise_feature['name']}"
else
  puts "❌ Feature não encontrada. Verifique config/features.yml"
  exit 1
end

# Verificar se está nas features compiladas
features = Featurable::FEATURES
puts "2. Features compiladas: #{features.count} features"

socialwise_key = nil
features.each do |key, feature_name|
  if feature_name.to_s.include?('SOCIALWISE_RICH_DASHBOARD')
    socialwise_key = key
    puts "✅ Feature encontrada na posição #{key}: #{feature_name}"
    break
  end
end

unless socialwise_key
  puts "❌ Feature não encontrada nas features compiladas"
  puts "Isso pode indicar que o servidor precisa ser reiniciado"
  exit 1
end

# Verificar a conta 3
puts "\n3. Verificando conta 3..."
account = Account.find(3)
puts "✅ Conta encontrada: #{account.name}"

# Verificar se o método existe
method_name = "feature_SOCIALWISE_RICH_DASHBOARD?"
if account.respond_to?(method_name)
  puts "✅ Método #{method_name} existe"
  current_state = account.send(method_name)
  puts "Estado atual: #{current_state}"
else
  puts "❌ Método #{method_name} não existe"
  puts "Métodos disponíveis:"
  account.methods.grep(/feature_.*\?$/).sort.each { |m| puts "  #{m}" }
  exit 1
end

# Habilitar a feature se não estiver habilitada
unless account.send(method_name)
  puts "\n4. Habilitando feature..."
  
  # Usar o método setter
  setter_method = "feature_SOCIALWISE_RICH_DASHBOARD="
  if account.respond_to?(setter_method)
    account.send(setter_method, true)
    account.save!
    puts "✅ Feature habilitada via setter"
  else
    puts "❌ Método setter não existe: #{setter_method}"
    exit 1
  end
end

# Verificar estado final
puts "\n5. Verificação final..."
account.reload
final_state = account.send(method_name)
puts "Estado final: #{final_state}"

if final_state
  puts "✅ SUCCESS: Feature está habilitada!"
  
  # Testar com o serviço
  puts "\n6. Testando Instagram Rich Message Service..."
  
  # Criar uma mensagem de teste
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
    
    service_result = service.send(:rich_dashboard_enabled?)
    puts "Resultado do serviço: #{service_result}"
    
    if service_result
      puts "✅ PERFEITO: Serviço detectou feature como habilitada!"
    else
      puts "❌ PROBLEMA: Serviço ainda detecta como desabilitada"
    end
  else
    puts "⚠️  Nenhuma conversa Instagram encontrada para teste"
  end
  
else
  puts "❌ FAILED: Feature ainda está desabilitada"
end

puts "\n=== CORREÇÃO CONCLUÍDA ==="