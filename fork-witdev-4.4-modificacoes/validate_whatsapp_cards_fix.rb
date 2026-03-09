#!/usr/bin/env ruby
# Script para validar a correção das mensagens ricas do WhatsApp

puts "=== VALIDAÇÃO DA CORREÇÃO DAS MENSAGENS RICAS DO WHATSAPP ==="
puts

# Verificar se existem mensagens com content_type 'cards' recentes
puts "1. Verificando mensagens com content_type 'cards':"
cards_messages = Message.where(content_type: 'cards')
                        .where('created_at > ?', 1.hour.ago)
                        .order(created_at: :desc)
                        .limit(5)

puts "   Mensagens encontradas (última hora): #{cards_messages.count}"

if cards_messages.any?
  cards_messages.each do |message|
    puts "   - ID: #{message.id}, Criada: #{message.created_at}"
    puts "     Conteúdo: #{message.content&.truncate(50)}"
    puts "     Atributos: #{message.content_attributes.keys.join(', ')}"
    
    if message.content_attributes['whatsapp_interactive_source']
      puts "     ✓ Convertida do WhatsApp Interactive"
    end
    
    if message.content_attributes['items']&.any?
      items_count = message.content_attributes['items'].length
      puts "     ✓ #{items_count} card(s) encontrado(s)"
      
      message.content_attributes['items'].each_with_index do |item, index|
        puts "       Card #{index + 1}: #{item['title']&.truncate(30)}"
        puts "         Ações: #{item['actions']&.length || 0}"
        puts "         Imagem: #{item['media_url'] ? 'Sim' : 'Não'}"
      end
    end
    puts
  end
else
  puts "   ❌ Nenhuma mensagem com content_type 'cards' encontrada na última hora"
end

puts "2. Verificando mensagens com content_type 'integrations' (WhatsApp Interactive):"
integrations_messages = Message.where(content_type: 'integrations')
                              .where('created_at > ?', 1.hour.ago)
                              .joins(:conversation)
                              .joins('JOIN inboxes ON conversations.inbox_id = inboxes.id')
                              .where('inboxes.channel_type = ?', 'Channel::Whatsapp')
                              .order(created_at: :desc)
                              .limit(5)

puts "   Mensagens encontradas (última hora): #{integrations_messages.count}"

if integrations_messages.any?
  integrations_messages.each do |message|
    puts "   - ID: #{message.id}, Criada: #{message.created_at}"
    puts "     Conteúdo: #{message.content&.truncate(50)}"
    
    if message.content_attributes['whatsapp_interactive_payload']
      interactive = message.content_attributes['whatsapp_interactive_payload']
      puts "     ✓ WhatsApp Interactive detectado"
      puts "       Tipo: #{interactive['type']}"
      
      if interactive['header'] && interactive['header']['type'] == 'image'
        puts "       ✓ Tem imagem no header"
      end
      
      if interactive['action'] && interactive['action']['buttons']
        buttons_count = interactive['action']['buttons'].length
        puts "       ✓ #{buttons_count} botão(ões)"
      end
    end
    puts
  end
else
  puts "   ✓ Nenhuma mensagem WhatsApp Interactive encontrada (esperado se a correção estiver funcionando)"
end

puts "3. Verificando logs recentes do SocialWise Flow:"
puts "   Procurando por logs de 'Should render as cards' nos últimos 30 minutos..."

# Simular busca por logs (isso dependeria do sistema de logs específico)
puts "   💡 Para verificar os logs, execute:"
puts "   tail -f log/development.log | grep 'Should render as cards'"
puts "   ou"
puts "   grep 'Should render as cards' log/development.log | tail -10"

puts
puts "=== VALIDAÇÃO CONCLUÍDA ==="
puts
puts "📋 PRÓXIMOS PASSOS:"
puts "1. Teste enviando uma mensagem rica do SocialWise Flow"
puts "2. Verifique se ela aparece como 'cards' no dashboard"
puts "3. Confirme se o componente RichCards.vue está sendo usado"
puts "4. Verifique os logs para confirmar a conversão"