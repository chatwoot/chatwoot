#!/usr/bin/env ruby
# Script de diagnóstico para SOCIALWISE_RICH_DASHBOARD

puts "=== DIAGNÓSTICO SOCIALWISE_RICH_DASHBOARD ==="

# 1. Verificar se a feature está no arquivo de configuração
puts "\n1. Verificando config/features.yml:"
feature_list = YAML.safe_load(Rails.root.join('config/features.yml').read)
socialwise_feature = feature_list.find { |f| f['name'] == 'SOCIALWISE_RICH_DASHBOARD' }

if socialwise_feature
  puts "✅ Feature encontrada:"
  puts "   Nome: #{socialwise_feature['name']}"
  puts "   Display: #{socialwise_feature['display_name']}"
  puts "   Habilitada por padrão: #{socialwise_feature['enabled']}"
else
  puts "❌ Feature não encontrada no config/features.yml"
  exit 1
end

# 2. Verificar se a feature está na lista de features do Featurable
puts "\n2. Verificando Featurable::FEATURES:"
features = Featurable::FEATURES
socialwise_key = features.values.find { |v| v.to_s.include?('SOCIALWISE_RICH_DASHBOARD') }

if socialwise_key
  puts "✅ Feature encontrada no Featurable::FEATURES: #{socialwise_key}"
else
  puts "❌ Feature não encontrada no Featurable::FEATURES"
  puts "Features disponíveis:"
  features.each { |k, v| puts "   #{k}: #{v}" }
end

# 3. Verificar a conta 3
puts "\n3. Verificando conta 3:"
begin
  account = Account.find(3)
  puts "✅ Conta encontrada: #{account.name}"
  
  # Verificar feature_flags da conta
  puts "   Feature flags (raw): #{account.feature_flags}"
  puts "   Feature flags (binary): #{account.feature_flags.to_s(2)}"
  
  # Verificar se tem o método para a feature
  method_name = "feature_SOCIALWISE_RICH_DASHBOARD?"
  if account.respond_to?(method_name)
    puts "✅ Método #{method_name} existe"
    enabled = account.send(method_name)
    puts "   Resultado: #{enabled}"
  else
    puts "❌ Método #{method_name} não existe"
    puts "   Métodos disponíveis que começam com 'feature_':"
    account.methods.grep(/^feature_/).each { |m| puts "     #{m}" }
  end
  
  # Testar feature_enabled?
  puts "\n   Testando feature_enabled?('SOCIALWISE_RICH_DASHBOARD'):"
  begin
    enabled = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
    puts "   ✅ Resultado: #{enabled}"
  rescue => e
    puts "   ❌ Erro: #{e.message}"
  end
  
  # Verificar todas as features habilitadas
  puts "\n   Features habilitadas:"
  begin
    enabled_features = account.enabled_features
    enabled_features.each { |name, enabled| puts "     #{name}: #{enabled}" }
    
    if enabled_features.key?('SOCIALWISE_RICH_DASHBOARD')
      puts "   ✅ SOCIALWISE_RICH_DASHBOARD está na lista: #{enabled_features['SOCIALWISE_RICH_DASHBOARD']}"
    else
      puts "   ❌ SOCIALWISE_RICH_DASHBOARD não está na lista de features habilitadas"
    end
  rescue => e
    puts "   ❌ Erro ao obter features habilitadas: #{e.message}"
  end
  
rescue ActiveRecord::RecordNotFound
  puts "❌ Conta 3 não encontrada"
rescue => e
  puts "❌ Erro: #{e.message}"
  puts e.backtrace.first(3)
end

# 4. Testar o Instagram Rich Message Service
puts "\n4. Testando Instagram Rich Message Service:"
begin
  account = Account.find(3)
  
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
      content: 'Teste',
      message_type: :outgoing
    )
    
    # Testar o serviço
    rich_payload = { 'template_type' => 'generic', 'elements' => [{ 'title' => 'Teste' }] }
    service = Instagram::RichMessageService.new(message: message, rich_payload: rich_payload)
    
    puts "   Testando rich_dashboard_enabled?:"
    enabled = service.send(:rich_dashboard_enabled?)
    puts "   Resultado: #{enabled}"
    
    if enabled
      puts "   ✅ Serviço detectou feature como habilitada"
    else
      puts "   ❌ Serviço detectou feature como desabilitada"
    end
    
  else
    puts "⚠️  Nenhuma conversa Instagram encontrada"
  end
  
rescue => e
  puts "❌ Erro no teste do serviço: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n=== FIM DO DIAGNÓSTICO ==="